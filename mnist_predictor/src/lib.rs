extern crate tokio;

use std::ffi::CString;
use std::net::SocketAddr;
use std::os::raw;
use std::str::FromStr;
use std::{ptr, slice};

use tokio::fs;
use tokio::net::TcpStream;
use tokio::prelude::*;
use tokio::runtime::{Builder, Runtime};
use tokio::sync::oneshot::{self, error::TryRecvError};

pub struct Predictor {
    rt: Runtime,
}
pub struct FuturePrediction {
    receiver: oneshot::Receiver<CString>,
}

fn generate_cstring(s: &str) -> CString {
    CString::new(s.as_bytes()).unwrap()
}
fn to_cstring(s: String) -> CString {
    CString::new(s.as_bytes()).unwrap_or_else(|_| generate_cstring("MessageError"))
}

#[no_mangle]
pub unsafe extern "cdecl" fn TryGetPredictionResult(
    futr: *mut FuturePrediction,
) -> *mut raw::c_char {
    match (*futr).receiver.try_recv() {
        Ok(s) => {
            Box::from_raw(futr);
            s.into_raw()
        }
        Err(TryRecvError::Empty) => ptr::null_mut(),
        Err(TryRecvError::Closed) => generate_cstring("FutureError").into_raw(),
    }
}

#[no_mangle]
pub unsafe extern "cdecl" fn RecycleResultMessage(s: *mut raw::c_char) {
    CString::from_raw(s);
}

#[no_mangle]
pub unsafe extern "cdecl" fn InitializePredictor() -> *mut Predictor {
    let mut builder = Builder::new();
    builder
        .threaded_scheduler()
        .core_threads(1)
        .max_threads(16)
        .enable_io();
    Box::into_raw(Box::new(Predictor {
        rt: match builder.build() {
            Ok(v) => v,
            Err(_) => return ptr::null_mut(),
        },
    }))
}

#[no_mangle]
pub unsafe extern "cdecl" fn FinalizePredictor(p: *mut Predictor) {
    Box::from_raw(p);
}

async fn predict(image: &[u8]) -> Result<String, &str> {
    let rawaddr = fs::read_to_string("mnist_predictor.addr")
        .await
        .or(Err("ConfigFileAccessError"))?;
    let addr = SocketAddr::from_str(rawaddr.trim()).or(Err("ParseAddressError"))?;
    let mut stream = TcpStream::connect(addr).await.or(Err("ConnectError"))?;
    stream.write_all(&image).await.or(Err("SendError"))?;
    let mut data = String::new();
    stream
        .read_to_string(&mut data)
        .await
        .or(Err("ReciveError"))?;
    Ok(data)
}
async fn predict_formated(image: &[u8], tx: oneshot::Sender<CString>) {
    tx.send(
        predict(image)
            .await
            .map_or_else(generate_cstring, to_cstring),
    )
    .unwrap_or_default();
}

#[no_mangle]
pub unsafe extern "cdecl" fn StartPrediction(
    state: *mut Predictor,
    image: *const u8,
) -> *mut FuturePrediction {
    let image = slice::from_raw_parts(image, 28 * 28);
    let (tx, rx) = oneshot::channel();

    (*state).rt.spawn(predict_formated(image, tx));
    Box::into_raw(Box::new(FuturePrediction { receiver: rx }))
}

#[no_mangle]
pub unsafe extern "cdecl" fn ThrowAwayPrediction(futr: *mut FuturePrediction) {
    Box::from_raw(futr);
}

#[no_mangle]
pub unsafe extern "cdecl" fn BlockingPredict(
    state: *mut Predictor,
    image: *const u8,
) -> *mut raw::c_char {
    let image = slice::from_raw_parts(image, 28 * 28);

    (*state)
        .rt
        .block_on(predict(image))
        .map_or_else(generate_cstring, to_cstring)
        .into_raw()
}

use std::io::prelude::*;
use std::net::TcpStream;
use std::os::raw;
use std::{ffi, fs, ptr, slice};

static mut PREDICT_RESULT_CSTR: *mut raw::c_char = ptr::null_mut();

#[no_mangle]
pub extern "C" fn MnistPredict(image: *const u8) -> *const raw::c_char {
    let image = unsafe { slice::from_raw_parts(image, 28 * 28) };

    let result = fs::read_to_string("mnist_predictor.addr")
        .or(Err("AddrError"))
        .and_then(|rawaddr| TcpStream::connect(rawaddr.trim()).or(Err("CnctError")))
        .and_then(|mut stream| {
            stream.write_all(&image).or(Err("TrnsError"))?;
            let mut data = String::new();
            stream.read_to_string(&mut data).or(Err("RecvError"))?;
            Ok(data)
        });
    let msg: &str = result.as_ref().map_or_else(|e| &e[..], |v| v);

    unsafe {
        if PREDICT_RESULT_CSTR != ptr::null_mut() {
            ffi::CString::from_raw(PREDICT_RESULT_CSTR);
        }
        PREDICT_RESULT_CSTR = ffi::CString::new(msg.as_bytes()).unwrap().into_raw();
        PREDICT_RESULT_CSTR
    }
}

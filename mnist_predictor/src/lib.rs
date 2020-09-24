use std::io::prelude::*;
use std::net::TcpStream;
use std::{fs, slice};

#[no_mangle]
pub extern "C" fn MnistPredict(image: *const u8) -> i32 {
    let image = unsafe { slice::from_raw_parts(image, 28 * 28) };

    fs::read_to_string("mnist_predictor.addr")
        .and_then(|raw| TcpStream::connect(raw.trim()))
        .and_then(|mut stream| {
            stream.write_all(&image)?;
            let mut data = [0; 4];
            stream.read_exact(&mut data)?;
            Ok(i32::from_le_bytes(data))
        })
        .unwrap_or(-1)
}

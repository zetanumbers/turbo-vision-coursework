use std::io::prelude::*;
use std::net::TcpStream;
use std::slice;

#[no_mangle]
pub extern "C" fn MnistPredictorInitialize() {}

#[no_mangle]
pub extern "C" fn MnistPredict(image: *const u8) -> i32 {
    let image = unsafe { slice::from_raw_parts(image, 28 * 28) };    
    let mut stream = TcpStream::connect("176.106.242.194:8765").unwrap();
    
    let mut data = [0; 1];

    stream.write(&image).unwrap();
    stream.read(&mut data).unwrap();

    data[0] as i32
}

#[no_mangle]
pub extern "C" fn MnistPredictorFinalize() {}

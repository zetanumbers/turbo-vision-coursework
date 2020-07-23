import asyncio, websockets, os, logging
import numpy as np
os.environ["CUDA_VISIBLE_DEVICES"] = "-1" 
from tensorflow.keras.models import load_model

model = load_model('mnist_cnn_model.h5')

print()
logging.root.setLevel(logging.DEBUG)
logging.basicConfig(format='%(asctime)-15s: %(message)s')

async def predict(websocket : websockets.WebSocketServerProtocol, path):
    try:
        while True:
            arr = await websocket.recv()
            
            arr = np.frombuffer(arr, dtype=np.uint8)
            pred = model.predict(arr.reshape((-1, 28, 28, 1)))
            prediction = np.argmax(pred, axis=1)[0]
            
            await websocket.send(str(prediction))
    except websockets.ConnectionClosedOK:
        pass
    except websockets.exceptions.ConnectionClosedError as e:
        pass

if __name__ == '__main__':
    start_server = websockets.serve(predict, "192.168.1.10", 8765, ping_interval=None)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()

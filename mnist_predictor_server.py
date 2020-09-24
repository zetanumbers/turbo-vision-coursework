import socketserver, os
import numpy as np
os.environ["CUDA_VISIBLE_DEVICES"] = "-1" 
from tensorflow.keras.models import load_model

model = load_model('mnist_cnn_model.h5')

# Debug related function
def pretty_img_print(img):
    for i in range(28):
        print(*(f'{x:02x}' for x in img[i, :]), sep='')

class MnistTCPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        # self.request is the TCP socket connected to the client
        self.data = self.request.recv(28 * 28)
        image = np.frombuffer(self.data, dtype=np.uint8)

        pred = model.predict(image.reshape((-1, 28, 28, 1)))
        prediction = np.argmax(pred, axis=1)[0]

        self.request.sendall((int(prediction)).to_bytes(4, 'little'))
        
        print(self.client_address)
        pretty_img_print(image.reshape((28, 28)))
        

if __name__ == "__main__":
    HOST, PORT = "192.168.1.10", 8765

    with socketserver.TCPServer((HOST, PORT), MnistTCPHandler) as server:
        server.serve_forever()
    
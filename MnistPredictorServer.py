import rpyc

class MyService(rpyc.Service):
    def on_connect(self, conn):
        import os
        os.environ["CUDA_VISIBLE_DEVICES"] = "-1" 
        from tensorflow.keras.models import load_model
        global np
        import numpy as np

        self.model = load_model('mnist_cnn_model.h5')

    def on_disconnect(self, conn):
        pass

    def exposed_predict(self, arr):
        arr = np.array(arr)
        pred = self.model.predict(arr.reshape((-1, 28, 28, 1)))
        prediction = np.argmax(pred, axis=1)[0]
        return prediction
        

if __name__ == "__main__":
    from rpyc.utils.server import ThreadedServer
    t = ThreadedServer(MyService, port=18861)
    t.start()
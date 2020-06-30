#include "mnist_predictor.h"

#define BOOST_PYTHON_STATIC_LIB

#include <boost/python.hpp>

#include <iterator>
#include <optional>
#include <stdexcept>
#include <type_traits>

namespace py = boost::python;

namespace my {
struct PythonInstance {
  PythonInstance() {
    if (!Py_IsInitialized()) {
      Py_Initialize();
    }
  }
};

struct Program : PythonInstance {
  struct {
    py::object main = py::import("__main__");
    py::object subprocess = py::import("subprocess");
    py::object rpyc = py::import("rpyc");
    py::object time = py::import("time");
  } modules;

  Program() {
    serverProcess = py::eval(
        "Popen(('python', 'MnistPredictorServer.py'),"
        "close_fds=True, creationflags=CREATE_NEW_CONSOLE)",
        modules.subprocess.attr("__dict__"));

    modules.time.attr("sleep")(0.1);
    connection = modules.rpyc.attr("connect")("localhost", 18861);
  }

  ~Program() {
    connection.attr("close")();
    serverProcess.attr("terminate")();
  }

  __int32 predict(const unsigned char* image) {
    using Elem = const unsigned char;

    py::list lsimage;
    for (auto it = image; it != image + 28 * 28; ++it) {
      lsimage.append(int(*it));
    }

    return py::extract<__int32>(
        py::long_(connection.attr("root").attr("predict")(lsimage)));
  }

  py::object serverProcess;
  py::object connection;
};

static std::optional<Program> program = std::nullopt;

}  // namespace my

void MnistPredictorInitialize() {
  my::program.emplace();
}

__int32 MnistPredict(const unsigned char* image) {
  return my::program->predict(image);
}

void MnistPredictorFinalize() {
  my::program.reset();
}

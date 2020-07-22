#include "mnist_predictor.h"

#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>

#include <iterator>
#include <optional>
#include <stdexcept>
#include <type_traits>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>

namespace beast = boost::beast;         // from <boost/beast.hpp>
namespace http = beast::http;           // from <boost/beast/http.hpp>
namespace websocket = beast::websocket; // from <boost/beast/websocket.hpp>
namespace net = boost::asio;            // from <boost/asio.hpp>
using tcp = boost::asio::ip::tcp;       // from <boost/asio/ip/tcp.hpp>

struct configuration {
  std::string host;
  std::string port;

  static configuration parse() {
    configuration result;

    static constexpr char config_file_name[] = "mnist_predictor.cfg";
    std::ifstream is_file(config_file_name);
    if (!is_file.is_open()) {
      throw std::runtime_error("Cannot open configuration file");
    }
    std::string line;
    while (std::getline(is_file, line))
    {
      std::istringstream is_line(line);
      std::string key;
      if (std::getline(is_line, key, '='))
      {
        std::string value;
        if (std::getline(is_line, value)) {
          if (key == "host") {
            result.host = std::move(value);
          }
          else if (key == "port") {
            result.port = std::move(value);
          }
        }
      }
    }
    return result;
  }
};

namespace my {
  struct Program {
    net::io_context ioc;
    tcp::resolver resolver{ ioc };
    websocket::stream<tcp::socket> ws{ ioc };

    Program() {
      auto config = configuration::parse();
      auto const results = resolver.resolve(config.host, config.port);
      auto ep = net::connect(ws.next_layer(), results);
      config.host += ':' + std::to_string(ep.port());

      ws.set_option(websocket::stream_base::decorator(
        [](websocket::request_type& req)
        {
          req.set(http::field::user_agent,
            std::string("mnist_predictor"));
        }));

      ws.handshake(config.host, "/");
    }

    ~Program() {
      ws.close(websocket::close_code::normal);
    }

    int predict(const unsigned char* image) {
      auto buf = net::buffer(static_cast<const void*>(image), 28 * 28);
      
      ws.binary(true);
      ws.write(buf);

      beast::flat_buffer buffer;
      ws.read(buffer);
      return *static_cast<const char*>(buffer.cdata().data()) - '0';
    }
  };

  static std::optional<Program> program = std::nullopt;

}  // namespace my

[[noreturn]] static void lippincott_log_error() {
  try {
    throw;
  }
  catch (std::exception const& e)
  {
    std::cerr << "Error: " << e.what() << std::endl;
    throw;
  }
}

void MnistPredictorInitialize() {
  try
  {
    my::program.emplace();
  }
  catch (...)
  {
    lippincott_log_error();
  }
}

int MnistPredict(const unsigned char* image) {
  try
  {
    return my::program->predict(image);
  }
  catch (...)
  {
    lippincott_log_error();
  }
}

void MnistPredictorFinalize() {
  try
  {
    my::program.reset();
  }
  catch (...)
  {
    lippincott_log_error();
  }
}

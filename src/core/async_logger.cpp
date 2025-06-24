
#include <core/async_logger.h>

class AsyncLogger::Impl {
public:
    Impl(): m_done(false) {
        m_worker = std::thread{&AsyncLogger::Impl::worker_thread_func, this};
    }

    ~Impl() {
        while (!m_queue.empty()) {}
        m_done = true;
        m_queue.push("");
        m_worker.join();
    }

    void log(std::string message) {
        m_queue.push(std::move(message));
    }


private:
    void worker_thread_func() {
        while (!m_done) {
            std::string message;
            m_queue.wait_and_pop(message);
            
            if (m_done && message.empty()) break;

            std::cout << message;
        }
    }


    std::atomic<bool> m_done;
    MessageQueue<std::string> m_queue;
    std::thread m_worker;
};

auto AsyncLogger::instance() -> AsyncLogger& {
    static AsyncLogger logger;
    return logger;
}

AsyncLogger::AsyncLogger(): pimpl(std::make_unique<Impl>()) { }
AsyncLogger::~AsyncLogger() = default;

void AsyncLogger::log(std::string message) {
    pimpl->log(std::move(message));
}

LogStream::LogStream() = default;

LogStream::~LogStream() {
     m_oss << '\n';
     AsyncLogger::instance().log(m_oss.str());
}

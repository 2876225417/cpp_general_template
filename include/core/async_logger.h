#ifndef ASYNC_LOGGER_H
#define ASYNC_LOGGER_H

#include <core/message_queue.hpp>
namespace labelimg::core::logger {

class LogStream: private NonCopyable  {
public:
    LogStream();
    ~LogStream();

    template <typename T>
    auto operator<<(const T& value) -> LogStream& {
        m_oss << value;
        return *this;
    }
private:
    std::ostringstream m_oss;
};

#define LOG LogStream()

class AsyncLogger: private Singleton<AsyncLogger> {
    MAKE_SINGLETON_NOT_DEFAULT_CTOR_DTOR(AsyncLogger)
public:
    static auto instance() -> AsyncLogger&;
    void log(std::string);
private:
    void worker_thread_func();

    class Impl;
    std::unique_ptr<Impl> pimpl;
};

} // namespace labelimg::core::logger
#endif // ASYNC_LOGGER_H
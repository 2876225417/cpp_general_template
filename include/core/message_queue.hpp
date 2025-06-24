#ifndef MESSAGE_QUEUE_H
#define MESSAGE_QUEUE_H

#include <core/queue.h>


namespace labelimg::core::queue {
template <typename T>
class MessageQueue: public Queue<T>, private NonCopyable{
public:
    MessageQueue() = default;
    ~MessageQueue() override = default; 
public:
    void wait_and_pop(T&);
    auto try_pop(T&) -> bool;
    
    void push(T) override;
    auto empty() const -> bool;
    auto size()  const -> size_t;
private:    
    mutable std::mutex m_mutex;
    std::condition_variable m_cond;
};

template <typename T>
void MessageQueue<T>::push(T value) {
    std::lock_guard<std::mutex> lock{m_mutex};

    Queue<T>::m_queue.push(std::move(value));

    m_cond.notify_one();
}

template <typename T>
void MessageQueue<T>::wait_and_pop(T& value) {
    std::unique_lock<std::mutex> lock{m_mutex};

    m_cond.wait(lock, [this] { return !Queue<T>::m_queue.empty(); });

    value = std::move(Queue<T>::m_queue.front());
    Queue<T>::m_queue.pop();
}

template <typename T>
auto MessageQueue<T>::try_pop(T& value) -> bool {
    std::lock_guard<std::mutex> lock{m_mutex};
    if (Queue<T>::m_queue.empty()) return false;
    value = std::move(Queue<T>::m_queue.front());
    Queue<T>::m_queue.pop();
    return true;
}

template <typename T>
auto MessageQueue<T>::empty() const -> bool {
    std::lock_guard<std::mutex> lock{m_mutex};
    return Queue<T>::m_queue.empty();
}

template <typename T>
auto MessageQueue<T>::size() const -> size_t  {
    std::lock_guard<std::mutex> lock{m_mutex};
    return Queue<T>::m_queue.size();
}

} // namespace labelimg::core::queue
#endif // MESSAGE_QUEUE_H
#ifndef QUEUE_H
#define QUEUE_H

#include <pch.h>

namespace labelimg::core::queue {
template <typename T>
class Queue{
public:
    virtual ~Queue() = default;

    virtual void push(T value) { m_queue.push(std::move(value)); }
    virtual void pop() { m_queue.pop(); }
    virtual auto front() -> T& { return m_queue.front();  };
    virtual auto empty() -> bool { return m_queue.empty(); }
    virtual auto size() -> size_t { return m_queue.size(); }
protected:
    std::queue<T> m_queue;
};
} // namespace labelimg::core::queue

#endif // QUEUE_H

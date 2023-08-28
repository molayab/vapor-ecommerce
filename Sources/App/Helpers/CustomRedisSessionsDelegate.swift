import Redis
import Vapor

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    func redis<Client: RedisClient>(
        _ client: Client,
        store data: SessionData,
        with key: RedisKey) -> EventLoopFuture<Void> {

            return client.set(key, toJSON: data).flatMap { _ in
                client.expire(key, after: .hours(12))
            }.map { _ in () }
    }

    func redis<Client: RedisClient>(
        _ client: Client,
        fetchDataFor key: RedisKey) -> EventLoopFuture<SessionData?> {

            return client.get(key, asJSON: SessionData.self)
    }
}

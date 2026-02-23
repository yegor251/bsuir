import Foundation

struct WeatherResponse: Codable {
    let main: Main?

    struct Main: Codable {
        let temp: Double
    }
}

struct CachedWeather: Codable {
    let city: String
    let temperature: Double
    let timestamp: Date

    var isValid: Bool {
        let thirtyMinutes: TimeInterval = 30 * 60
        return Date().timeIntervalSince(timestamp) < thirtyMinutes
    }
}

final class WeatherService {
    static let shared = WeatherService()

    private let cacheKey = "weatherCache"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func fetchWeather(for city: String) async throws -> Double? {
        print("WeatherService.fetchWeather start, city=\(city)")
        let cached = getCachedWeather(for: city)
        let validCachedTemperature = (cached?.isValid == true) ? cached?.temperature : nil
        print("WeatherService.fetchWeather cached=\(String(describing: cached)), isValid=\(cached?.isValid ?? false)")

        if let temperature = try await fetchFromAPI(for: city) {
            print("WeatherService.fetchWeather got API temperature=\(temperature)")
            saveToCache(city: city, temperature: temperature)
            return temperature
        }

        if let validCachedTemperature {
            print("WeatherService.fetchWeather using valid cached temperature=\(validCachedTemperature)")
            return validCachedTemperature
        }

        if let cached {
            print("WeatherService.fetchWeather using stale cached temperature=\(cached.temperature)")
            return cached.temperature
        }

        print("WeatherService.fetchWeather no data available")
        return nil
    }

    private func fetchFromAPI(for city: String) async throws -> Double? {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("WeatherService: invalid city name")
            return nil
        }

        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&units=metric&appid=b828d2f6310149513856d084cfba7060"
        guard let url = URL(string: urlString) else {
            print("WeatherService: invalid URL")
            return nil
        }

        do {
            print("WeatherService.fetchFromAPI requesting URL=\(url)")
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("WeatherService: non-200 response, status=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }

            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            print("WeatherService.fetchFromAPI decoded response, main.temp=\(String(describing: weatherResponse.main?.temp))")
            return weatherResponse.main?.temp
        } catch {
            print("WeatherService error:", error)
            return nil
        }
    }

    private func getCachedWeather(for city: String) -> CachedWeather? {
        guard let data = userDefaults.data(forKey: cacheKey) else { return nil }

        do {
            let cache = try JSONDecoder().decode([String: CachedWeather].self, from: data)
            return cache[city]
        } catch {
            print("WeatherService: failed to decode cache:", error)
            return nil
        }
    }

    private func saveToCache(city: String, temperature: Double) {
        var cache: [String: CachedWeather] = [:]

        if let data = userDefaults.data(forKey: cacheKey) {
            do {
                cache = try JSONDecoder().decode([String: CachedWeather].self, from: data)
            } catch {
                print("WeatherService: failed to decode existing cache:", error)
            }
        }

        let cached = CachedWeather(city: city, temperature: temperature, timestamp: Date())
        cache[city] = cached

        do {
            let data = try JSONEncoder().encode(cache)
            userDefaults.set(data, forKey: cacheKey)
        } catch {
            print("WeatherService: failed to encode cache:", error)
        }
    }
}


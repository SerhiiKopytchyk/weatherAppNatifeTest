//
//  WeatherViewModel.swift
//  weatherNatife
//
//  Created by Serhii Kopytchuk on 06.12.2022.
//

import SwiftUI
import MapKit
import Combine

class WeatherViewModel: ObservableObject {

    // MARK: - vars

    var locationManager = LocationManager()

    let requestedDataWebSite = "https://api.weatherapi.com/v1/"
    let key = "d0a9ecd662d7487b911111422221903"

    let decoder = JSONDecoder()

    private var subscriptions = Set<AnyCancellable>()

    enum UserDefaultsKeys: String {
        case lastSavedLatitude, lastSavedLongitude
    }

    @AppStorage(UserDefaultsKeys.lastSavedLatitude.rawValue) var lastSavedLatitude: Double = 48.8566
    @AppStorage(UserDefaultsKeys.lastSavedLongitude.rawValue) var lastSavedLongitude: Double = 2.3522


    @Published var lastSavedLocation: CLLocationCoordinate2D?

    @Published var weather: Weather?

    @Published var currentDay: Forecastday?

    @Published var locations = [SearchLocation]()

    @Published var lastMark: Mark?

    @Published var isShowLoader = false

    @Published var alertMessage = ""


    var weatherUrl = URL(string: "https://api.weatherapi.com/v1/forecast.json?key=d0a9ecd662d7487b911111422221903&q=London&days=10&aqi=no&alerts=no")

    // MARK: - computed properties

    var requestForecastString: String {
        return "\(requestedDataWebSite)forecast.json?key=\(key)&"
    }

    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }

    // MARK: - init

    init() {
        self.lastSavedLocation = CLLocationCoordinate2D(latitude: lastSavedLatitude, longitude: lastSavedLongitude)
        self.weatherUrl = URL(string: "\(requestForecastString)&q=\(lastSavedLatitude),\(lastSavedLongitude)&days=10&aqi=no&alerts=no")
    }

    // MARK: - functions

    func changeLocation(cityName: String) {
        self.weatherUrl = URL(string: "\(requestForecastString)&q=\(cityName)&days=10&aqi=no&alerts=no")
        self.getWeather { _ in
        }
    }

    func changeLocation(location: CLLocationCoordinate2D) {
        self.weatherUrl = URL(string: "\(requestForecastString)q=\(location.latitude),\(location.longitude)&days=10&aqi=no&alerts=no")
        lastMark = Mark(coordinate: location)
        getWeather { _ in }
    }

    func switchToCurrentLocation(accessToLocationDenied: () -> Void) {
        if let _ = locationManager.lastLocation {
            self.weatherUrl = URL(string: "\(requestForecastString)&q=\(userLatitude),\(userLongitude)&days=10&aqi=no&alerts=no")
            getWeather { _ in }
        } else {
            accessToLocationDenied()
        }
    }
    
    func getPlacesList(text: String) {
        guard let locationURL = URL(string: "\(requestedDataWebSite)search.json?key=\(key)&q=\(text)") else { return }

        URLSession.shared
            .dataTaskPublisher(for: locationURL)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .map(\.data)
            .decode(type: [SearchLocation].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .retry(3)
            .sink { competition in
                if case .failure(let error) = competition {
                    print(error)
                }
            } receiveValue: { value in
                self.locations = value
            }
            .store(in: &subscriptions)
    }


    func getWeather(competition: (Error?) -> Void) {

        showLoader()

        guard let weatherUrl = weatherUrl else { return }


        URLSession.shared
            .dataTaskPublisher(for: weatherUrl)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .map(\.data)
            .decode(type: Weather.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .retry(3)
            .sink { competition in
                if case .failure(let error) = competition {
                    self.hideLoader()
                    self.alertMessage = "failed to get data \(error.localizedDescription)"
                } else {
                    self.hideLoader()
                }
            } receiveValue: { weather in

                self.weather = weather

                self.lastSavedLocation = CLLocationCoordinate2D(latitude: self.weather?.location.lat ?? 0,
                                                                longitude: self.weather?.location.lon ?? 0)

                self.saveCoordinates(coordinates: self.lastSavedLocation)
                self.hideLoader()
            }
            .store(in: &subscriptions)

    }

    private func showLoader() {
        withAnimation(.easeInOut) {
            isShowLoader = true
        }
    }

    private func hideLoader() {
        withAnimation(.easeInOut) {
            isShowLoader = false
        }
    }

    func saveCoordinates(coordinates: CLLocationCoordinate2D?) {
        lastSavedLatitude = coordinates?.latitude ?? 0.0
        lastSavedLongitude = coordinates?.longitude ?? 0.0
    }
}

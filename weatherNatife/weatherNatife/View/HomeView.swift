//
//  HomeView.swift
//  weatherNatife
//
//  Created by Serhii Kopytchuk on 06.12.2022.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation

struct HomeView: View {

    @EnvironmentObject var weatherViewModel: WeatherViewModel

    let headerHeight: CGFloat
    let hourlyForecastHeight: CGFloat
    let dailyForecastHeight: CGFloat

    let imageWidth: CGFloat

    @State var currentDay: Forecastday?

    @State var currentImageURL: URL?

    init() {
        let screenHeightPercent = UIScreen.main.bounds.size.height / 100
        self.imageWidth = UIScreen.main.bounds.size.width / 2


        self.headerHeight = 30 * screenHeightPercent
        self.hourlyForecastHeight = 15 * screenHeightPercent
        self.dailyForecastHeight = 40 * screenHeightPercent
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Image("ic_place")
                        .foregroundColor(.white)
                        .font(.title2)
                    Text(weatherViewModel.weather?.location.name ?? "")
                        .foregroundColor(.white)
                        .font(.title2)

                    Spacer()
                    Image("ic_my_location")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity, alignment: .top)

                Text(currentDay?.dateEpoch.toDate.toDateTime ?? "")
                    .font(.callout)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                DayDetailedView(day: $currentDay, imageWidth: imageWidth)

            }
            .clipShape(Rectangle())
            .frame(maxWidth: .infinity)
            .frame(height: headerHeight)
            .background {
                Color.darkBlue
                    .ignoresSafeArea()
            }

            HourScrollView(currentDay: $currentDay)
            .clipShape(Rectangle())
            .frame(maxWidth: .infinity)
            .frame(height: hourlyForecastHeight)
            .background {
                Color.blue
            }


            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(  weatherViewModel.weather?.forecast.forecastday ?? [], id: \.id) { day in
                        DayListRow(day: day, currentDay: $currentDay)
                            .padding(.horizontal)
                            .anchorPreference(key: BoundsPreference.self, value: .bounds, transform: { anchor in
                                return [(day.id  ): anchor]
                            })
                    }
                }
                .overlayPreferenceValue(BoundsPreference.self) { values in
                    if let currentDay {
                            if let preference = values.first(where: { item in
                                item.key == currentDay.id
                            }) {
                                GeometryReader { proxy in
                                    let rect = proxy[preference.value]
                                    highlightedDay(for: currentDay, rect: rect)
                                }
                                .transition(.asymmetric(insertion: .identity, removal: .offset(x: 1)))
                            }
                    }
                }
            }
            .clipShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: weatherViewModel.weather?.forecast.forecastday ?? [], perform: { forecastDays in
            self.currentDay = forecastDays.first
        })

    }

    @ViewBuilder private func highlightedDay(for highlightDay: Forecastday, rect: CGRect) -> some View {
        DayListRow(day: highlightDay, currentDay: $currentDay)
            .padding(.horizontal)
            .background {
                Rectangle()
                    .fill(.white)
                    .shadow(color: .blue, radius: 10, x: 0, y: 0)

            }
            .shadow(color: .blue.opacity(0.25), radius: 24, x: 0, y: 0)
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
        
    }

}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WeatherViewModel())
    }
}


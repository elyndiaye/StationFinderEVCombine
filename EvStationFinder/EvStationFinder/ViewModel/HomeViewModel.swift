//
//  HomeViewModel.swift
//  EvStationFinder
//
//  Created by Ely Assumpcao Ndiaye on 05/07/25.
//


import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var stations : [EvStation] = []
    @Published var isLoading : Bool = false
    @Published var errorMessage : String?
    @Published var showAlert =  false
    @Published var zipCode: String = Foundation.UserDefaults.standard.string(forKey: "LastZipCode") ?? ""
    
    
    private let service : NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }
    
    func loadStations(){
        guard isValidZipCode() else { return }
        
        UserDefaults.standard.set(zipCode, forKey: "LastZipCode")
        
        self.isLoading = true
        
        
        service.fetchStationList(zipCode: zipCode)
            .receive(on: DispatchQueue.main)
            .sink (receiveCompletion: { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.showError(message: error.message)
                }
            },receiveValue: { [weak self] stations in
                self?.handleStationsResponse(stations: stations)
            }).store(in: &cancellables)
                   
    }
    
    private func isValidZipCode() -> Bool {
        if zipCode.isEmpty {
            showError(message: HomeStrings.zipCodeIsRequired)
            return false
        }
        
        if zipCode.count != 5 || Int(zipCode) == nil {
            showError(message: HomeStrings.zipCodeNeedToBeValid)
            return false
        }
        
        return true
    }
    
    private func handleStationsResponse(stations: [EvStation]) {
           self.stations = stations
           if stations.isEmpty {
               showError(message: HomeStrings.noStationsFoundZipCode)
           }
       }
    
    
    private func showError(message: String) {
        self.errorMessage = message
        self.showAlert = true
    }
    
    
}

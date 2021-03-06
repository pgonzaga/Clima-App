//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON


class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {

    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"

    let locationManager = CLLocationManager()
    let weatherDatamodel = WeatherDataModel()
    var celsius : Bool = true

    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    @IBAction func changeSwitchUnit(_ sender: UISwitch) {

        if sender.isOn {
            let newTemperature : Int =  kelvinToCelsius(degrees: weatherDatamodel.temperature)
            weatherDatamodel.temperature = newTemperature
        } else {
            let newTemperature : Int =  celsiusToKelvin(degrees: weatherDatamodel.temperature)
            weatherDatamodel.temperature = newTemperature
        }

        temperatureLabel.text = "\(weatherDatamodel.temperature)"

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(parameters: [String: String], url: String) {

        Alamofire.request(WEATHER_URL, method: .get,  parameters: parameters).responseJSON {
            response in

            if response.result.isSuccess {
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
                self.updateUIWithWeather()
            } else {
                self.showErrorMessage()
            }
        }

    }

    //MARK: - JSON Parsing
    /***************************************************************/

    func updateWeatherData(json: JSON) {

        if let temp = json["main"]["temp"].double {
            let cityName = json["name"].stringValue
            let conditionID = json["weather"][0]["id"].intValue

            weatherDatamodel.temperature = calcTemp(degrees: temp)
            weatherDatamodel.city = cityName
            weatherDatamodel.condition = conditionID
            weatherDatamodel.weatherIconName = weatherDatamodel.updateWeatherIcon(condition: conditionID)
        } else {
            showErrorMessage()
        }

    }

    //MARK: - UI Updates
    /***************************************************************/
    
    func showErrorMessage() {
        cityLabel.text = "Weather unavailable"
    }

    func updateUIWithWeather() {
        cityLabel.text = weatherDatamodel.city
        temperatureLabel.text = "\(weatherDatamodel.temperature)"
        weatherIcon.image = UIImage(named: weatherDatamodel.weatherIconName)
    }
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location : CLLocation = locations[locations.count - 1]

        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil

            let latitude : CLLocationDegrees = location.coordinate.latitude
            let longitude : CLLocationDegrees = location.coordinate.longitude

            let params :  [String : String] = ["lat": String(latitude), "lon": String(longitude), "appid": APP_ID]

            getWeatherData(parameters: params, url: WEATHER_URL)
        }

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

        print(error)
        cityLabel.text = "There was an error trying to get your location."

    }

    //MARK: - Change City Delegate methods
    /***************************************************************/
    func userHasEnteredCityName(city: String) {

        let params : [String: String] = ["q": city, "appid": APP_ID]
        getWeatherData(parameters: params, url: WEATHER_URL)

    }
    
    //Write the PrepareForSegue Method here

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }

    }

    //MARK: - Temperature measurement
    /***************************************************************/

    func calcTemp(degrees: Double) -> Int{

        if celsius {
            return Int(degrees - 273.15)
        } else {
            return Int(degrees)
        }

    }

    func celsiusToKelvin(degrees: Int) -> Int {
        return degrees + 273
    }

    func kelvinToCelsius(degrees: Int) -> Int {
        return degrees - 273
    }
}



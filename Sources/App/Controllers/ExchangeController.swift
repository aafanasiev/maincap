//
//  ExchangeController.swift
//  App
//
//  Created by Aleksandr Afanasiev on 29.12.2018.
//

import Vapor

final class ExchangeController {


    func tickers(_ req: Request) throws -> String {
        
        
        
        return ""
    }
    
    
    
    func sendPush(_ req: Request) throws -> String  {
        
        let group = DispatchGroup()
      
        var ourTickers = [String : Double]()
        var tickers = [String : String]()
        
        // 1. Get saved tickers
        group.enter()
        getOurTickers { (arr) in
            if let array = arr {
                ourTickers = array
                print("1 - DONE")
                group.leave()
            }
        }
        group.wait()
        
        // 2. Get tickers from exchange
        group.enter()
        getBinancePriceTickers { (tick) in
            if let tic = tick {
                tickers = tic
                print("2 - DONE")
                group.leave()
            }
        }
        group.wait()
     
        let theJSONData = try? JSONSerialization.data(withJSONObject: tickers, options: [.prettyPrinted])
     
        // 3. Put tickers to DB
        let session = URLSession.shared
        let url = URL(string: "https://fantasyfootball-f0d7d.firebaseio.com/binance.json")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        
        request.httpBody = theJSONData
        
        session.dataTask(with: request) { (data, resp, error) in
            print("Done")
        }.resume()
        
        tickers["TAAS"] = "13.45"
        
        // 4. Compare
        let changes = compareTickers(old: ourTickers, new: tickers)
        print("Changes: \(changes)")
        
        // 5. Send Push
        
        
        return ""
    }
    
    
    func compareTickers(old: [String : Double], new: [String : String]) -> [String : Double] {
        
        var result = [String : Double]()
        
        old.forEach { temp in
            
            let oldValue = temp.value
            let newValue = Double(new[temp.key] ?? "") ?? -1
            
            let change = ((newValue - oldValue) / oldValue) * 100
            
            result[temp.key] = change
            
        }
        
        return result
    
    }
    
    
    func ticker(_ req: Request) throws -> String  {
        
        let group = DispatchGroup()
        var tickerArray = [[String : AnyObject]]()
        
   
        var tickers = [String : String]()
        
        // 2. Get tickers from exchange
        group.enter()
        getBinancePriceTickers { (tick) in
            if let tic = tick {
                tickers = tic
                group.leave()
            }
        }
        group.wait()
        
                getBinanceTickers { tickers in
        
                    if let tic = tickers {
                        tickerArray = tic
                        group.leave()
                    }
        
//                                tickerArray = tickers!
        
                }
        print(tickerArray)

        
        let theJSONData = try? JSONSerialization.data(withJSONObject: tickers, options: [.prettyPrinted])
        
        let theJSONText = String(data: theJSONData!, encoding: .utf8)
        
        
        let session = URLSession.shared
        let url = URL(string: "https://fantasyfootball-f0d7d.firebaseio.com/binance.json")

        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"

        request.httpBody = theJSONData

        session.dataTask(with: request) { (data, resp, error) in

        }.resume()
        
        return theJSONText!
        
    }
    
    
    func getOurTickers(completion: @escaping([String : Double]?) -> Void) {
        
        let session = URLSession.shared
        let url = URL(string: "https://fantasyfootball-f0d7d.firebaseio.com/binance.json")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        session.dataTask(with: request) { (data, resp, error) in
        
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                   
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : AnyObject] else {return}
            
                    
                    
                    var arr = [String : Double]()
                    
                    array.forEach({ dict in
                        
//                        print("Dict: \(dict)")
                        
                        arr[dict.key] = Double(dict.value as! String)!
                    })
                    
                    arr["TAAS"] = 15.04
                    
                    completion(arr)
                    
                } catch {
                    
                }
            }
        }.resume()
        
    }
    
    func getBinancePriceTickers(completion: @escaping([String : String]?) -> Void) {
        
        var tickers = [String:String]()
        
        let session = URLSession.shared
        let url = URL(string: "https://api.binance.com/api/v1/ticker/24hr")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : Any]] else {return}
                    
                    
                    _ = array.filter({ dict -> Bool in
                        if let symbol = dict["symbol"] as? String {
                            if symbol == "BTCUSDT" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["weightedAvgPrice"] as? String {
                            
                            usdPrice = Double(price)!
                            
                        }
                        
                    })
                    
                    _ = array.map({ dict -> Void in
                        if let symbol = dict["symbol"] as? String, let price = dict["weightedAvgPrice"] as? String {
                            if symbol.suffix(3) == "BTC" && Double(price)! != 0 {
                               
                                let sym = symbol.dropLast(3).description
                                let tickerUSDPrice = (Double(price)! * usdPrice)
                            
                                tickers[sym] = tickerUSDPrice.description
                             }
                        }
                    })
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    
//    func getBinanceTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
//        
//        var tickers = [[String:AnyObject]]()
//        
//        let session = URLSession.shared
//        let url = URL(string: "https://api.binance.com/api/v1/ticker/24hr")
//        
//        var request = URLRequest(url: url!)
//        request.httpMethod = "GET"
//        
//        session.dataTask(with: request) { (data, resp, error) in
//            
//            if error != nil {
//                completion(nil)
//            }
//            
//            if let dat = data {
//                
//                do {
//                    
//                    var usdPrice: Double = 0
//                    var yesterdayPrice: Double = 0
//                    
//                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : Any]] else {return}
//                    
//                    
//                    _ = array.filter({ dict -> Bool in
//                        if let symbol = dict["symbol"] as? String {
//                            if symbol == "BTCUSDT" {
//                                return true
//                            }
//                        }
//                        return false
//                    }).map({ dict -> Void in
//                        
//                        if let price = dict["weightedAvgPrice"] as? String, let change = dict["priceChange"] as? String {
//                            
//                            usdPrice = Double(price)!
//                            yesterdayPrice = Double(price)! - Double(change)!
//                            
//                        }
//                        
//                    })
//                    
//                    _ = array.map({ dict -> Void in
//                        if let symbol = dict["symbol"] as? String, let price = dict["weightedAvgPrice"] as? String, let change = dict["priceChangePercent"] as? String, let changeValue = dict["priceChange"] as? String {
//                            if symbol.suffix(3) == "BTC" && Double(price)! != 0 {
//                                //                                print("\(symbol) - \(price) - \(change)")
//                                
//                                let sym = symbol.dropLast(3).description
//                                let tickerUSDPrice = (Double(price)! * usdPrice)
//                                print(sym)
//                                
//                                let assetYesterdayPice = Double(price)! - Double(changeValue)!
//                                
//                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
//                                
//                                let changeUSD = (tickerUSDPrice - tickerYesterdayPrice) / tickerYesterdayPrice
//                                
//                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
//                                
//                                let ticker = ["symbol" : sym,
//                                              "priceBTC" : price,
//                                              "changeBTC" : changeBTC.stringValue,
//                                              "priceUSDT" : tickerUSDPrice.description,
//                                              "changeUSDT" : changeUSD.description]
//                                
//                                
//                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
//                                tickers.append(ticker as [String : AnyObject])
//                                
//                            }
//                        }
//                    })
//                    
//                    completion(tickers)
//                    
//                } catch {
//                    print("Error: cannot create JSON from todo")
//                    return
//                }
//                
//                
//            }
//            
//            }.resume()
//    }
//    
//    func getBittrexTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
//        
//        var tickers = [[String:AnyObject]]()
//        
//        let session = URLSession.shared
//        let url = URL(string: "https://bittrex.com/api/v1.1/public/getmarketsummaries")
//        
//        var request = URLRequest(url: url!)
//        request.httpMethod = "GET"
//        
//        session.dataTask(with: request) { (data, resp, error) in
//            
//            if error != nil {
//                completion(nil)
//            }
//            
//            if let dat = data {
//                
//                do {
//                    
//                    var usdPrice: Double = 0
//                    var yesterdayPrice: Double = 0
//                    
//                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any], let result = array["result"] as? [[String : AnyObject]] else {return}
//                    
//                    
//                    
//                    _ = result.filter({ dict -> Bool in
//                        if let symbol = dict["MarketName"] as? String {
//                            if symbol == "USDT-BTC" {
//                                return true
//                            }
//                        }
//                        return false
//                    }).map({ dict -> Void in
//                        
//                        if let price = dict["Last"] as? Double, let prevDay = dict["PrevDay"] as? Double {
//                            
//                            
//                            usdPrice = price
//                            yesterdayPrice = prevDay
//                            
//                        }
//                        
//                    })
//                    
//                    _ = result.map({ dict -> Void in
//                        if let symbol = dict["MarketName"] as? String, let price = dict["Last"] as? Double, let prevDay = dict["PrevDay"] as? Double {
//                            
//                            if symbol.prefix(4) == "BTC-" {
//                                //                                print("\(symbol) - \(price) - \(change)")
//                                
//                                let sym = symbol.dropFirst(4).description
//                                
//                                let tickerUSDPrice = price * usdPrice
//                                
//                                let changeBTC = (price - prevDay) / prevDay
//                                
//                                let priceBTC = NSDecimalNumber(value: price)
//                                
//                                
//                                let assetYesterdayPice = yesterdayPrice * price * prevDay
//                                
//                                //                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
//                                
//                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
//                                
//                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
//                                
//                                let ticker = ["symbol" : sym,
//                                              "priceBTC" : priceBTC.stringValue,
//                                              "changeBTC" : changeBTC.description,
//                                              "priceUSDT" : tickerUSDPrice.description,
//                                              "changeUSDT" : changeUSD.description]
//                                
//                                
//                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
//                                tickers.append(ticker as [String : AnyObject])
//                                
//                            }
//                        }
//                    })
//                    
//                    
//                    completion(tickers)
//                    
//                } catch {
//                    print("Error: cannot create JSON from todo")
//                    return
//                }
//                
//                
//            }
//            
//            }.resume()
//    }
//    
//    
//    func getHitBTCTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
//        
//        var tickers = [[String:AnyObject]]()
//        
//        let session = URLSession.shared
//        let url = URL(string: "https://api.hitbtc.com/api/2/public/ticker")
//        
//        var request = URLRequest(url: url!)
//        request.httpMethod = "GET"
//        
//        session.dataTask(with: request) { (data, resp, error) in
//            
//            if error != nil {
//                completion(nil)
//            }
//            
//            if let dat = data {
//                
//                do {
//                    
//                    var usdPrice: Double = 0
//                    var yesterdayPrice: Double = 0
//                    
//                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : AnyObject]] else {return}
//                    
//                    _ = array.filter({ dict -> Bool in
//                        if let symbol = dict["symbol"] as? String {
//                            if symbol == "BTCUSD" {
//                                return true
//                            }
//                        }
//                        return false
//                    }).map({ dict -> Void in
//                        
//                        if let price = dict["last"] as? String, let prevDay = dict["open"] as? String {
//                            
//                            
//                            usdPrice = Double(price)!
//                            yesterdayPrice = Double(prevDay)!
//                            
//                        }
//                        
//                    })
//                    
//                    _ = array.map({ dict -> Void in
//                        if let symbol = dict["symbol"] as? String, let price = dict["last"] as? String, let prevDay = dict["open"] as? String {
//                            
//                            if symbol.suffix(3) == "BTC" {
//                                //                                print("\(symbol) - \(price) - \(change)")
//                                
//                                let sym = symbol.dropLast(3).description
//                                
//                                
//                                let tickerUSDPrice = Double(price)! * usdPrice
//                                
//                                let changeBTC = (Double(price)! - Double(prevDay)!) / Double(prevDay)!
//                                
//                                let priceBTC = Double(price)!
//                                
//                                
//                                let assetYesterdayPice = yesterdayPrice * Double(price)! * Double(prevDay)!
//                                
//                                //                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
//                                
//                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
//                                
//                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
//                                
//                                let ticker = ["symbol" : sym,
//                                              "priceBTC" : priceBTC.description,
//                                              "changeBTC" : changeBTC.description,
//                                              "priceUSDT" : tickerUSDPrice.description,
//                                              "changeUSDT" : changeUSD.description]
//                                
//                                
//                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
//                                tickers.append(ticker as [String : AnyObject])
//                                
//                            }
//                        }
//                    })
//                    
//                    //                    print(tickers)
//                    
//                    completion(tickers)
//                    
//                } catch {
//                    print("Error: cannot create JSON from todo")
//                    return
//                }
//                
//                
//            }
//            
//            }.resume()
//    }
    
    
    
    func getCAP() {
        
        
        let session = URLSession.shared
        let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?limit=2500")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : AnyObject]] else {return}
                    
                    _ = array.map({ dict -> Void in
                        
                        let symbol = dict["symbol"] as! String
                        let name = dict["name"] as! String
                        
                        print(name)
                        print(symbol)
                        
                    })
                    
                    //                    print(array)
                    
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
        
    }
}

extension Double {

    func eightPoints() -> String? {
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.maximumFractionDigits = 8
        
        return currencyFormatter.string(from: NSNumber(value: self))
        
    }

}

//
//  ViewController.swift
//  Example
//
//  Created by indianrenters on 12/02/25.
//

import UIKit
import OneLoginSDKiOS

enum SectionInTable  {
    case Token(_ type: RowsInTable)
    case Factors (_ type: RowsInTable)
    case Users(_ type: RowsInTable)
    
    func getTitle() -> String {
        switch self {
        case .Token(let token):
            return token.rowTitle()
        case .Factors(let factors):
            return factors.rowTitle()
        case .Users(let user):
            return user.rowTitle()
        }
    }
    
    func headerTitle() -> String {
        switch self {
        case .Token:
            return "Tokens Section"
        case .Factors:
            return "Factors Section"
        case .Users:
            return "Users Section"
        }
    }
}

enum RowsInTable: CaseIterable {
    case GenrateToken, Revoke, Limit
    case AllFactors, Enroll, VerifyRegistration, StatusRegistration, Enrolled, Activate, VerifyFactor, StatusFactor,TempMFA, RemoveFactor
    case AllUser, Detail, Create, Update, Delete
    
    func rowTitle() -> String {
        return "\(self)"
    }
}

class ViewController: UIViewController {
    struct Constants {
        static let clientID = "<CLIENT_ID>"
        static let clientSecret = "<CLIENT_SECRET>"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var arrDataSource : [SectionInTable] = [.Token(.GenrateToken),.Token(.Revoke), .Token(.Limit),
                                            //Factors
                                            .Factors(.AllFactors),.Factors(.Enroll), .Factors(.VerifyRegistration),
                                            .Factors(.StatusRegistration), .Factors(.Enrolled), .Factors(.Activate),
                                            .Factors(.VerifyFactor),
                                            .Factors(.StatusFactor), .Factors(.TempMFA), .Factors(.RemoveFactor),
                                            // Users
                                            .Users(.AllUser),.Users(.Detail),.Users(.Create),.Users(.Update),.Users(.Delete)
                                            ]
    
    var selectedUser: UserModel?
    var createdUser: UserCreationModal?
    var createdUserCount: Int = 0
    var verificationId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        registerTableViewCell()
        
        let mfaConfig = OneLoginSdkConfig(credential: (Constants.clientID, Constants.clientSecret), subDomain: "<Domain>")
        OneLoginSDK.shared.intializeSdk(mfaConfig)
    }
    
    private func registerTableViewCell() {
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "cellExample")
    }
    
    func showAlert(_ message: String) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(message)
            }
            return
        }
        
        // Create an instance of UIAlertController
        let alert = UIAlertController(title: "MFA alert", message: message, preferredStyle: .alert)

        // Add an action (button) to the alert
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)

        // Add the action to the alert
        alert.addAction(okAction)

        // Present the alert from the current view controller
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellExample", for: indexPath) as? TableViewCell
        else {return UITableViewCell()}

        cell.titleLabel.text = arrDataSource[indexPath.row].getTitle()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrDataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = arrDataSource[indexPath.row]
        switch selected {
        case .Token(.GenrateToken):
            generateToken()
        case .Token(.Revoke):
            revokeToken()
        case .Token(.Limit):
            getRateLimit()
        case .Factors(.AllFactors):
            if let userId = self.selectedUser?.id {
                getAllFactors(userId: userId) { [weak self] success, availableFactors, error in
                    let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
                    self?.showAlert(alertMessage)
                }
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.Enroll):
            if let userId = self.selectedUser?.id {
                getAllFactors(userId: userId) { [weak self] success, availableFactors, error in
                    if let factorDetail = availableFactors?.last, let factorId = factorDetail.factor_id {
                        self?.enrollFactor(userId: userId, factorId: factorId)
                    } else {
                        self?.showAlert("Factor Id not found")
                    }
                }
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.VerifyRegistration):
            if let userId = self.selectedUser?.id {
                verifyEnrollment(userId: userId, registrationId: "<Please fill registratin ID from Enroll factor>", otp: "<Please fill OTP recieved>")
            }
            
        case .Factors(.Enrolled):
            if let userId = self.selectedUser?.id {
                getEnrolledFactors(userId: userId) { [weak self] success, enrolledFactors, error in
                    let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
                    self?.showAlert(alertMessage)
                }
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.VerifyFactor):
            if let userId = self.selectedUser?.id {
                //Please fill same device Id as sent in activate factor.
                self.verifyFactorOTP(userId: userId, otp: "<Please fill OTP recieved>", deviceId: 0000, verificationId: self.verificationId ?? "")
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.StatusRegistration):
            if let userId = self.selectedUser?.id {
                isEnrollmentOfFactorVerified(userId: userId, registrationId: "<Please fill registratin ID from Enroll factor>")
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.Activate):
            if let userId = self.selectedUser?.id {
                getEnrolledFactors(userId: userId) { [weak self] success, enrolledFactors, error in
                    if let deviceID = enrolledFactors?.first?.device_id {
                        self?.activateFactor(userId: userId, deviceId: deviceID, completion: { [weak self] success, factorDetail, error in
                            self?.verificationId = factorDetail?.id
                            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
                            self?.showAlert(alertMessage)
                        })
                    } else {
                        self?.showAlert("No Device Id Found")
                    }
                }
            } else {
                showAlert("No User Found - Click User List First")
            }
        case .Factors(.StatusFactor):
            if let userId = self.selectedUser?.id {
                isFactorVerified(userId: userId, verificationId: "<Please fill verification ID from activate factor>")
            } else {
                showAlert("No User Found - Click User List First")
            }
            
        case .Factors(.TempMFA):
            if let userId = self.selectedUser?.id {
                generateTempMFAToken(userId: userId)
            } else {
                showAlert("No User Found - Click User List First")
            }
            
        case .Factors(.RemoveFactor):
            if let userId = self.selectedUser?.id {
                // Please fill device ID from enrolled factors
                removeFactor(userId: userId, deviceId: 00000)
            } else {
                showAlert("No User Found - Click User List First")
            }
            
        case .Users(.AllUser):
            getUsersList { [weak self] success, usersList, error in
                self?.selectedUser = usersList?.last
            }
        case .Users(.Detail):
            if let userId = self.selectedUser?.id {
                getUserDetail(userId: userId)
            }else {
                showAlert("No Selected User Found")
            }
        case .Users(.Create):
            createUser()
        case .Users(.Update):
            if let userId = self.createdUser?.id {
                updateUser(userId: userId)
            } else {
                showAlert("No User Found")
            }
        case .Users(.Delete):
            if let userId = self.createdUser?.id {
                deleteUser(userId: userId)
            } else {
                showAlert("No User Found")
            }
        default:
            ""
        }
    }
}

extension ViewController {
    private func generateToken() {
        OneLoginSDK.shared.genrateToken { [weak self] success, tokenDetail, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")

            print("Generate Token - Success - \(success)")
            print("Generate Token - Response - \(String(describing: tokenDetail))")
            print("Generate Token - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func revokeToken() {
        OneLoginSDK.shared.revokeToken { [weak self] success, status, error in
            print("Revoke Token - Success - \(success)")
            print("Revoke Token - Status - \(String(describing: status))")
            print("Revoke Token - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func getRateLimit() {
        OneLoginSDK.shared.getRateLimit { [weak self] success, rateLimit, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("getRateLimit - Success - \(success)")
            print("getRateLimit - \(String(describing: rateLimit))")
            print("getRateLimit - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func getUsersList(completion: @escaping (_ success: Bool, _ usersList: [UserModel]?, _ error: ApiError?) -> Void) {
        OneLoginSDK.shared.getUsersList { success, usersList, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("UserList - Success - \(success)")
            print("UserList - \(String(describing: usersList))")
            print("UserList - Error - \(String(describing: error))")
            
            completion(success, usersList, error)
        }
    }
    
    private func getUserDetail(userId: Int) {
        OneLoginSDK.shared.getUser(userId: "\(userId)") { [weak self] success, userDetail, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("UserDetail - Success - \(success)")
            print("UserDetail - \(String(describing: userDetail))")
            print("UserDetail - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func createUser() {
        createdUserCount += 1
        OneLoginSDK.shared.createUser(username: "Tomato_\(createdUserCount)", email: "tomato_\(createdUserCount)@yopmail.com", mappings: .asyncMapping, validatePolicy: nil,
                                 otherAttributes: ["password":"Qwerty@12345678",
                                                   "password_confirmation":"Qwerty@12345678",
                                                   "phone": "+91"]) { [weak self] success, userDetail, error in
            print("createUser - Success - \(success)")
            print("createUser - \(String(describing: userDetail))")
            print("createUser - Error - \(String(describing: error))")
            
            self?.createdUser = userDetail
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func updateUser(userId: Int) {
        OneLoginSDK.shared.updateUser(id: userId, mappings: .syncMapping, validatePolicy: true,
                                 updateAttributes: ["company":"vegeis"]) { [weak self] success, userDetail, error in
            print("updateUser - Success - \(success)")
            print("updateUser - \(String(describing: userDetail))")
            print("updateUser - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func deleteUser(userId: Int) {
        OneLoginSDK.shared.deleteUser(id: userId) { [weak self] success, error in
            print("deleteUser - Success - \(success)")
            print("deleteUser - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func generateTempMFAToken(userId: Int) {
        OneLoginSDK.shared.getMFAToken(userId: "\(userId)", expiresIn: 300, reusable: true) { [weak self] success, tempMFA, error in
            print("getMFAToken - Success - \(success)")
            print("getMFAToken - TokenModel - \(String(describing: tempMFA))")
            print("getMFAToken - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func getAllFactors(userId: Int, completion: @escaping (_ success: Bool, _ availableFactors: [AvailableFactorsModel]?, _ error: ApiError?) -> Void) {
        OneLoginSDK.shared.getAvailableFactors(userId: "\(userId)") { success, availableFactors, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("getAvailableFactors - Success - \(success)")
            print("getAvailableFactors - \(String(describing: availableFactors))")
            print("getAvailableFactors - Error - \(String(describing: error))")
            
            completion(success, availableFactors, error)
        }
    }
    
    private func enrollFactor(userId: Int, factorId: Int) {
        OneLoginSDK.shared.enrollFactor(userId: "\(userId)", factorId: factorId, displayName: "Factor Test") { [weak self] success, enrolledFactor, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("enrollFactor - Success - \(success)")
            print("enrollFactor - \(String(describing: enrolledFactor))")
            print("enrollFactor - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func getEnrolledFactors(userId: Int, completion: @escaping (_ success: Bool, _ enrolledFactors: [EnrolledFactorsModel]?, _ error: ApiError?) -> Void) {
        OneLoginSDK.shared.getEnrolledFactors(userId: "\(userId)") { success, enrolledFactors, error in
            print("---------------------------- -------------- ---------------- -------------- ------------------ ------------")
            print("getEnrolledFactors - Success - \(success)")
            print("getEnrolledFactors - \(String(describing: enrolledFactors))")
            print("getEnrolledFactors - Error - \(String(describing: error))")
            
            completion(success, enrolledFactors, error)
        }
    }
    
    private func activateFactor(userId: Int, deviceId: String, completion: @escaping (_ success: Bool, _ factorDetail: ActivateFactorsModel?, _ error: ApiError?) -> Void) {
        OneLoginSDK.shared.activateFactor(userId: "\(userId)",
                                     deviceId: deviceId, expiresIn: nil) { success, factorDetail, error in
            print("activateFactor - Success - \(success)")
            print("activateFactor - \(String(describing: factorDetail))")
            print("activateFactor - Error - \(String(describing: error))")
            
            completion(success, factorDetail, error)
        }
    }
    
    private func isFactorVerified(userId: Int, verificationId: String) {
        OneLoginSDK.shared.isFactorVerified(userId: "\(userId)", verificationId: verificationId) {[weak self] success, statusFactor, error in
            print("isFactorVerified - Success - \(success)")
            print("isFactorVerified - \(String(describing: statusFactor))")
            print("isFactorVerified - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func isEnrollmentOfFactorVerified (userId: Int, registrationId: String) {
        OneLoginSDK.shared.isEnrollmentOfFactorVerified(userId: "\(userId)", registrationId: registrationId) { [weak self] success, statusFactor, error in
            print("isEnrollmentOfFactorVerified - Success - \(success)")
            print("isEnrollmentOfFactorVerified - \(String(describing: statusFactor))")
            print("isEnrollmentOfFactorVerified - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func removeFactor(userId: Int, deviceId: Int) {
        OneLoginSDK.shared.removeFactor(userId: "\(userId)", deviceId: deviceId) {[weak self] success, error in
            print("removeFactor - Success - \(success)")
            print("removeFactor - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func verifyFactorOTP(userId: Int, otp: String, deviceId: Int?, verificationId: String) {
        OneLoginSDK.shared.verifyFactorOTP(userId: "\(userId)", otp: otp, deviceId: deviceId, verificationId: verificationId) { [weak self] success, verificationStatus, error in
            print("verifyFactorOTP - Success - \(success)")
            print("verifyFactorOTP - \(String(describing: verificationStatus))")
            print("verifyFactorOTP - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
    
    private func verifyEnrollment(userId: Int, registrationId: String, otp: String) {
        OneLoginSDK.shared.verifyEnrollment(userId: "\(userId)", registrationId: registrationId, otp: otp) { [weak self] success, error in
            print("verifyEnrollment - Success - \(success)")
            print("verifyEnrollment - Error - \(String(describing: error))")
            
            let alertMessage = success ? "Success" : (error?.errorDescription ?? "Error")
            self?.showAlert(alertMessage)
        }
    }
}

//
//  MainViewController.swift
//  Tinodios
//
//  Created by Djaka Permana on 09/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import UIKit
import TinodeSDK
import TinodiosDB
import PhoneNumberKit
import Combine

enum LoginError: Error {
    case unauthorize
    case fatalError(String)
    case errorConnection(String)
    
    var message: String {
        switch self {
        case .unauthorize:
            return "unauthorize"
        case .fatalError(let error):
            return "Login Error: \(error)"
        case .errorConnection(let error):
            return "Error Connection: \(error)"
        }
    }
}

enum RegisterError: Error {
    case alreadyExist
    case fatalError(String)
    
    var message: String {
        switch self {
        case .alreadyExist:
            return "User already exist"
        case .fatalError(let error):
            return "Error register: \(error)"
        }
    }
}

class MainViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var orderIdTextField: UITextField!
    @IBOutlet weak var loginRegisterButton: UIButton!
    @IBOutlet weak var openChatButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    private var credMethods: [String] = [Credential.kMethPhone]
    private var avatarReceived: Bool = false
    private var tinode: Tinode!
    static let kTopicUriPrefix = "tinode:topic/"
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad(){
        super.viewDidLoad()

        SharedUtils.removeAuthToken()
        Cache.invalidate()
        
        initialView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title="Main";
    }
    
    private func initialView() {
        usernameTextField.isHidden = false
        usernameTextField.isEnabled = true
        orderIdTextField.isHidden = true
        usernameTextField.text = ""
        orderIdTextField.text = ""
        
        loginRegisterButton.isEnabled = true
        openChatButton.isEnabled = false
        signOutButton.isEnabled = false
    }
    
    private func successLoginOrRegisterView() {
        orderIdTextField.text = ""
        orderIdTextField.isHidden = false
        usernameTextField.isEnabled = false
        loginRegisterButton.isEnabled = false
        openChatButton.isEnabled = true
        signOutButton.isEnabled = true
    }
    
    @IBAction func loginRegisterAction(_ sender: Any) {
        
        let userName = usernameTextField.text ?? ""
        let password = userName
        
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).count <= 5 {
            UiUtils.showToast(message: String("Minimum character is 6"))
        } else {
            onSignUpTinode(userName: userName, password: password)
//            onSignInTinode(userName: userName, password: password)
        }
    }
    
    private func onSignInTinode(userName: String, password: String) {
        doSignInTinode(userName: userName, password: password)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    switch error as? LoginError {
                    case .unauthorize:
                        self.onSignUpTinode(userName: userName, password: password)
                    default:
                        UiUtils.showToast(message: String("Authentication failed " + error.localizedDescription))
                        print("SIGN IN TINODE ERROR: ", error.localizedDescription)
                    }
                case .finished:
                    print("SIGN IN TINODE: Finish")
                }
            }, receiveValue: {_ in
                self.loginChatService(userName: userName, password: password)
            })
            .store(in: &self.cancellables)
    }
    
    private func loginChatService(userName: String, password: String) {
        let tinode = Cache.tinode
        print("SIGN IN CHAT SERVICE: ", tinode.myUid ?? "")

        let service = AuthService(buildLevel: .development)
        service.authRequest(userId: userName, tinodeId: tinode.myUid ?? "")
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("SIGN IN CHAT SERVICE: ", error.localizedDescription)
                    UiUtils.showToast(message: String("Authentication failed " + error.localizedDescription))
                    self.onSignOut()
                case .finished:
                    print("SIGN IN CHAT SERVICE: Finish")
                }
            }, receiveValue: { responseState in
                print("SIGN IN CHAT SERVICE: ", responseState.rawValue)
                
                if responseState == .isSuccess {
                    UiUtils.showToast(message: String("Authentication successfull"))
                    self.successLoginOrRegisterView()
                    Cache.setUserId(userId: userName)
                } else {
                    UiUtils.showToast(message: String("Authentication failed"))
                    self.onSignOut()
                }
            })
            .store(in: &self.cancellables)
    }
    
    @IBAction func openChat(_ sender: Any) {
        let orderId = orderIdTextField.text ?? ""
        
        if orderId.trimmingCharacters(in: .whitespacesAndNewlines).count <= 5 {
            UiUtils.showToast(message: String("Check minimum character of participant id and order Id"))
        } else {
            self.getParticipant(orderId: orderId)
        }
    }
    
    private func getParticipant(orderId: String) {
        let service = ParticipantService(buildLevel: .development)
        service.getParticipant(orderId: orderId)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    UiUtils.showToast(message: String("Get Participant failed " + error.localizedDescription))
                case .finished:
                    print("SIGN UP FINISH")
                }
            }, receiveValue: { response in
                self.navigateToChat(chatRoomId: response.chat_room_id, callRoomId: response.call_room_id)
            })
            .store(in: &self.cancellables)
    }
    
    private func navigateToChat(chatRoomId: String, callRoomId: String) {
        let messageVC = MessageViewController()
        messageVC.topicName = chatRoomId
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    @IBAction func signOut(_ sender: Any) {
        initialView()
        onSignOut()
    }
    
    private func onSignUpTinode(userName: String, password: String) {
        let username = userName
        let password = password
        let name = username
        let description = ""
        let avatar: UIImage? = nil
        let creds = [Credential]()
        
        func doSignUp(withPublicCard pub: TheCard, withCredentials creds: [Credential]) -> AnyPublisher<Bool, Error> {
            
            return Future<Bool, Error> { completion in
                
                let tinode = Cache.tinode
                let desc = MetaSetDesc<TheCard, String>(pub: pub, priv: nil)
                desc.attachments = pub.photoRefs

                do {
                    try tinode.connectDefault(inBackground: false)?
                        .thenApply { _ in
                            return Cache.tinode.createAccountBasic(uname: username, pwd: password, login: true, tags: nil, desc: desc, creds: creds)
                        }
                        .thenApply { msg in
                            SharedUtils.saveAuthToken(for: username, token: tinode.authToken, expires: tinode.authTokenExpires)
                            completion(.success(true))
                            return nil
                        }
                        .thenCatch { err in
                            if let tinodeErr = err as? TinodeError {
                                if let errorText = tinodeErr.errorDescription, errorText.contains("409") {
                                    completion(.failure(RegisterError.alreadyExist))
                                } else {
                                    completion(.failure(RegisterError.fatalError(tinodeErr.description)))
                                }
                            } else {
                                completion(.failure(RegisterError.fatalError(err.localizedDescription)))
                            }
                            return nil
                        }
                } catch(let error) {
                    Cache.tinode.disconnect()
                    completion(.failure(error))
                }
                
            }.eraseToAnyPublisher()
        }
        
        func onSignUp(withPublicCard pub: TheCard, withCredentials creds: [Credential]) {
            doSignUp(withPublicCard: pub, withCredentials: creds)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        switch error as? RegisterError {
                        case .alreadyExist:
                            self.onSignInTinode(userName: userName, password: password)
                        default:
                            UiUtils.showToast(message: String("Authentication failed " + error.localizedDescription))
                            print("SIGN UP TINODE: ", error.localizedDescription)
                        }
                    case .finished:
                        print("SIGN UP FINISH")
                    }
                }, receiveValue: { _ in
                    self.onSignInTinode(userName: userName, password: password)
                })
                .store(in: &self.cancellables)
        }
        
        onSignUp(withPublicCard: TheCard(fn: name, avatar: avatar, note: description), withCredentials: creds)
    }
    
    /// Login to tinode service
    private func doSignInTinode(userName: String, password: String) -> AnyPublisher<Bool, Error> {

        return Future<Bool, Error> { completion in
            let tinode = Cache.tinode
            print("COMBINE: ", tinode.myUid ?? "")
            
            do {
                try tinode.connectDefault(inBackground: false)?
                    .thenApply({ _ in
                            return tinode.loginBasic(uname: userName, password: password)
                        })
                    .then(
                        onSuccess: { pkt in
                            Cache.log.info("LoginVC - login successful for %@", tinode.myUid!)
                            SharedUtils.saveAuthToken(for: userName, token: tinode.authToken, expires: tinode.authTokenExpires)
                            if let token = tinode.authToken {
                                tinode.setAutoLoginWithToken(token: token)
                            }
                            if let ctrl = pkt?.ctrl, ctrl.code >= 300, ctrl.text.contains("validate credentials") {
                                
                                completion(.failure(LoginError.fatalError(ctrl.text)))
                            }

                            completion(.success(true))
                            return nil
                        }, onFailure: { err in

                            Cache.log.error("LoginVC - login failed: %@", err.localizedDescription)

                            if let tinodeErr = err as? TinodeError {
                                Cache.log.error("Login Credentials")
                                
                                if let errorText = tinodeErr.errorDescription, errorText.contains("401") {
                                    completion(.failure(LoginError.unauthorize))
                                } else {
                                    completion(.failure(LoginError.fatalError(err.localizedDescription)))
                                }
                                
                            } else {
                                Cache.log.error("Couldn't connect to server")
                                completion(.failure(LoginError.errorConnection(err.localizedDescription)))
                                Cache.invalidate()
                            }

                            return nil
                        })
                } catch (let error) {
                    completion(.failure(error))
                }
        }.eraseToAnyPublisher()
    }
    
    private func onSignOut() {
        SharedUtils.removeAuthToken()
        Cache.invalidate()
        Cache.clearUserId()
    }
    
}

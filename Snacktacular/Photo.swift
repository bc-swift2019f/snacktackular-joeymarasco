//
//  Photo.swift
//  Snacktacular
//
//  Created by Joseph Marasco on 11/10/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Photo {
    var image: UIImage
    var description: String
    var postedBy: String
    var date: Date
    var documentUUID: String // Universal Unique Identifier
    var dictionary: [String:Any] {
        return ["description": description, "postedBy": postedBy, "Date": date]
    }
    
    
    init(image: UIImage, description: String, postedBy: String, date: Date, documentUUID: String) {
        self.image = image
        self.description = description
        self.postedBy = postedBy
        self.date = date
        self.documentUUID = documentUUID
    }
    
    convenience init() {
        let postedBy = Auth.auth().currentUser?.email ?? "Unknown User"
        self.init(image: UIImage(), description: "", postedBy: postedBy, date: Date(), documentUUID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let description = dictionary["description"] as! String? ?? ""
        let postedBy = dictionary["postedBy"] as! String? ?? ""
        let date = dictionary["date"] as! String? ?? String
        self.init(image: UIImage(), description: description, postedBy: postedBy, date: date, documentUUID: "")
    }

    func saveData(spot: Spot, completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        // convert photo.image to a data type so it can be saved in cloud firestore
        guard let photoData = self.image.jpegData(compressionQuality: 0.5) else {
            print("ERROR: could not convert image to data type")
            return completed(false)
        }
        let uploadMeta = StorageMetadata()
        uploadMeta.contentType = "image/jpeg"
        documentUUID = UUID().uuidString // create a unique id to use for the photo in firestore
        // create a ref to upload storage to the bucket with the name we created
        let storageRef = storage.reference().child(spot.documentID).child(self.documentUUID)
        let uploadTask = storageRef.putData(photoData, metadata: uploadMeta) {metadata, error in
            guard error == nil else {
                print("ERROR during putDataStorageUpload for reference \(storageRef), error: \(error!.localizedDescription)")
                return
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            let dataToSave = self.dictionary
            let ref = db.collection("spots").document(spot.documentID).collection("photos").document(self.documentUUID)
            ref.setData(self.dictionary) { (error) in
                if let error = error {
                    print("****ERROR: updating document \(self.documentUUID) in spot \(spot.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("****ERROR: updating document \(self.documentUUID) with ref \(ref.documentID)")
                    completed(true)
                }
            }
        }
            
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: upload task for file\(self.documentUUID) failed")
            }
            return completed(false)
        }
    }
}




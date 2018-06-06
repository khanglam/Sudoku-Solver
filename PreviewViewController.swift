//
//  PreviewViewController.swift
//  SudokuSolver
//
//  Created by Khang Lam on 5/14/18.
//  Copyright © 2018 Khang Lam. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {

    var image : UIImage!
    
    @IBOutlet weak var photo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photo.image = self.image
        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

  


}

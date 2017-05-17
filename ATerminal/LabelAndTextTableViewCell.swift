//
//  LabelAndTextTableViewCell.swift
//  ATerminal
//
//  Created by Daniel Tan on 16/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

class LabelAndTextTableViewCell: UITableViewCell {
    
    @IBOutlet var label:UILabel!
    @IBOutlet var textField:UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  HostNameAndStatusTableViewCell.swift
//  ATerminal
//
//  Created by Daniel Tan on 14/06/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

class HostNameAndStatusTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  DKAssetGroupListVC.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/8/8.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import Photos

let DKImageGroupCellIdentifier = "DKImageGroupCellIdentifier"

@objc public protocol DKAssetGroupCellType {
    static var preferredHeight: CGFloat { get }
    func configure(with assetGroup: DKAssetGroup, tag: Int, dataManager: DKImageGroupDataManager, imageRequestOptions: PHImageRequestOptions)
}

class DKAssetGroupCell: UITableViewCell, DKAssetGroupCellType {
    static var preferredHeight: CGFloat = 71

    class DKAssetGroupSeparator: UIView {

        override var backgroundColor: UIColor? {
            get {
                return super.backgroundColor
            }
            set {
                if newValue != UIColor.clear {
                    super.backgroundColor = newValue
                }
            }
        }
    }

    fileprivate lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 3
        thumbnailImageView.clipsToBounds = true
        

        return thumbnailImageView
    }()

    lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "PingFangTC-Regular", size: 15)
        label.textColor = UIColor(red: 45/255, green: 45/255, blue: 45/255, alpha: 1)
        
        return label
    }()

    
    var customSelectedBackgroundView: UIView = {
        let selectedBackgroundView = UIView()
        
        let selectedFlag = UIImageView(image: DKImagePickerControllerResource.blueTickImage())

        selectedFlag.frame = CGRect(x: selectedBackgroundView.bounds.width - selectedFlag.bounds.width - 20,
                                    y: (selectedBackgroundView.bounds.width - selectedFlag.bounds.width) / 2,
                                    width: selectedFlag.bounds.width, height: selectedFlag.bounds.height)
        selectedFlag.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        selectedBackgroundView.addSubview(selectedFlag)
        
        return selectedBackgroundView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectedBackgroundView = self.customSelectedBackgroundView

        self.contentView.addSubview(self.thumbnailImageView)
        self.contentView.addSubview(self.groupNameLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let spacingHeight:CGFloat = 6.5
        
        let imageViewHeight = CGFloat(56)
        self.thumbnailImageView.frame = CGRect(x: CGFloat(15),
                                               y: CGFloat(spacingHeight),
                                               width: imageViewHeight,
                                               height: imageViewHeight)

        self.groupNameLabel.frame = CGRect(
            x: self.thumbnailImageView.frame.maxX + 10,
            y: self.thumbnailImageView.frame.minY + 15,
            width: 200,
            height: 26)
    }

    func configure(with assetGroup: DKAssetGroup, tag: Int, dataManager: DKImageGroupDataManager, imageRequestOptions: PHImageRequestOptions) {
        self.tag = tag
        let name = assetGroup.groupName!
        let attributed = NSMutableAttributedString(string: name)
        attributed.addAttribute(.kern, value: 1.07, range: NSRange(location: 0, length: attributed.length - 1))

        groupNameLabel.attributedText = attributed
        
        if assetGroup.totalCount == 0 {
            thumbnailImageView.image = DKImagePickerControllerResource.emptyAlbumIcon()
        } else {
            dataManager.fetchGroupThumbnail(
                with: assetGroup.groupId,
                size: CGSize(width: DKAssetGroupCell.preferredHeight, height: DKAssetGroupCell.preferredHeight).toPixel(),
                options: imageRequestOptions) { [weak self] image, info in
                    if self?.tag == tag {
                        self?.thumbnailImageView.image = image
                    }
            }
        }
    }
    
    open func setLabelBold(bold: Bool) {
        if (bold == true) {
            groupNameLabel.font = UIFont(name: "PingFangTC-Medium", size: 15)
        } else {
            groupNameLabel.font = UIFont(name: "PingFangTC-Regular", size: 15)
        }
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////

class DKAssetGroupListVC: UITableViewController, DKImageGroupDataManagerObserver {

    fileprivate var groups: [String]? {
        didSet {
            self.displayGroups = self.filterEmptyGroupIfNeeded()
        }
    }

    private var displayGroups: [String]?

    var showsEmptyAlbums = true

    fileprivate var selectedGroup: String?

    fileprivate var defaultAssetGroup: PHAssetCollectionSubtype?

    fileprivate var selectedGroupDidChangeBlock:((_ group: String?)->())?

    fileprivate lazy var groupThumbnailRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact

        return options
    }()

    override var preferredContentSize: CGSize {
        get {
            if let groups = self.displayGroups {
                return CGSize(width: UIView.noIntrinsicMetric,
                              height: CGFloat(groups.count) * self.tableView.rowHeight)
            } else {
                return super.preferredContentSize
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    private var groupDataManager: DKImageGroupDataManager!

    internal weak var imagePickerController: DKImagePickerController!
    
    fileprivate let cellSpacingHeight: CGFloat = CGFloat(15)

    init(imagePickerController: DKImagePickerController,
         defaultAssetGroup: PHAssetCollectionSubtype?,
         selectedGroupDidChangeBlock: @escaping (_ groupId: String?) -> ()) {
        super.init(style: .plain)

        self.imagePickerController = imagePickerController
        self.groupDataManager = imagePickerController.groupDataManager
        self.defaultAssetGroup = defaultAssetGroup
        self.selectedGroupDidChangeBlock = selectedGroupDidChangeBlock
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imagePickerController.UIDelegate.imagePickerControllerPrepareGroupListViewController(self)

        let cellType = self.imagePickerController.UIDelegate.imagePickerControllerGroupCell()
        self.tableView.register(cellType, forCellReuseIdentifier: DKImageGroupCellIdentifier)
        self.tableView.rowHeight = cellType.preferredHeight
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 6.5,left: 0,bottom: 6.5,right: 0)

        self.clearsSelectionOnViewWillAppear = false

        self.navigationItem.title = DKImagePickerControllerResource.localizedStringWithKey("picker.albums")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self,
                                                                action: #selector(cancelButtonPressed))

        self.groupDataManager.add(observer: self)
    }

    internal func loadGroups() {
        self.groupDataManager.fetchGroups { [weak self] groups, error in
            guard let groups = groups, let strongSelf = self, error == nil else { return }

            strongSelf.groups = groups
            strongSelf.selectedGroup = strongSelf.defaultAssetGroupOfAppropriate()
            if let selectedGroup = strongSelf.selectedGroup, let displayGroups = strongSelf.displayGroups, let row = displayGroups.index(of: selectedGroup) {
                strongSelf.tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
                strongSelf.selectedGroupDidChangeBlock?(strongSelf.selectedGroup)
            }
        }
    }

    fileprivate func defaultAssetGroupOfAppropriate() -> String? {
        guard let groups = self.displayGroups else { return nil }

        if let defaultAssetGroup = self.defaultAssetGroup {
            for groupId in groups {
                guard let group = self.groupDataManager.fetchGroup(with: groupId) else { continue }

                if defaultAssetGroup == group.originalCollection?.assetCollectionSubtype {
                    return groupId
                }
            }
        }
        return groups.first
    }

    private func filterEmptyGroupIfNeeded() -> [String]? {
        if self.showsEmptyAlbums {
            return self.groups
        } else {
            return self.groups?.filter({ (groupId) -> Bool in
                guard let group = self.groupDataManager.fetchGroup(with: groupId) else {
                    assertionFailure("Expect group")
                    return false
                }
                return group.totalCount > 0
            }) ?? []
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayGroups?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let groups = self.displayGroups
            , let cell = tableView.dequeueReusableCell(withIdentifier: DKImageGroupCellIdentifier, for: indexPath) as? DKAssetGroupCell else {
                assertionFailure("Expect groups and cell")
                return UITableViewCell()
        }

        guard let assetGroup = self.groupDataManager.fetchGroup(with: groups[indexPath.row]) else {
            assertionFailure("Expect group")
            return UITableViewCell()
        }

        cell.configure(with: assetGroup, tag: indexPath.row + 1, dataManager: groupDataManager, imageRequestOptions: groupThumbnailRequestOptions)
        
        if assetGroup.groupId == self.selectedGroup {
            cell.setLabelBold(bold: true)
        } else {
            cell.setLabelBold(bold: false)
        }

        return cell as! UITableViewCell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            DKPopoverViewController.dismissPopoverViewController()
        }

        guard let groups = self.displayGroups, groups.count > indexPath.row else {
            assertionFailure("Expect groups with count > \(indexPath.row)")
            return
        }

        self.selectedGroup = groups[indexPath.row]
        
        // change the selected group to bold, and unselected to normal
        for cell in tableView.visibleCells {
            let c = cell as! DKAssetGroupCell
            if c.tag == indexPath.row + 1 {
                c.setLabelBold(bold: true)
            } else {
                c.setLabelBold(bold: false)
            }
        }
        
        selectedGroupDidChangeBlock?(self.selectedGroup)
    }
    

    // MARK: - DKImageGroupDataManagerObserver methods

    func groupDidUpdate(groupId: String) {
        self.displayGroups = self.filterEmptyGroupIfNeeded()

        let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
        self.tableView.reloadData()
        self.tableView.selectRow(at: indexPathForSelectedRow, animated: false, scrollPosition: .none)
    }

    func groupsDidInsert(groupIds: [String]) {
        self.groups! += groupIds

        self.willChangeValue(forKey: "preferredContentSize")

        let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
        self.tableView.reloadData()
        self.tableView.selectRow(at: indexPathForSelectedRow, animated: false, scrollPosition: .none)

        self.didChangeValue(forKey: "preferredContentSize")
    }

    func groupDidRemove(groupId: String) {
        guard let row = self.groups?.index(of: groupId) else { return }

        self.willChangeValue(forKey: "preferredContentSize")

        self.groups?.remove(at: row)

        self.tableView.reloadData()
        if self.selectedGroup == groupId {
            self.selectedGroup = self.displayGroups?.first
            selectedGroupDidChangeBlock?(self.selectedGroup)
            self.tableView.selectRow(at: IndexPath(row: 0, section: 0),
                                     animated: false,
                                     scrollPosition: .none)
        }

        self.didChangeValue(forKey: "preferredContentSize")
    }

    @objc func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
}

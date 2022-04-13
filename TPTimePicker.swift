//
//  TPTimePicker.swift
//
//  Created by Thang Phung on 05/04/2022.
//

import Foundation
import UIKit

private let WIDTH_COMPONENT: CGFloat = 92
private let HEIGHT_COMPONENT: CGFloat = 34
private let WIDTH_COMPONENT_LABEL: CGFloat = 30
private let HIGHLIGHT_COLOR = UIColor.orange

class TPTimePicker: UIView {
    fileprivate enum EditableType {
        case all
        case hours
        case minute
        case cancel
    }
    
    private var pickerView: UIPickerView!
    private var textField: UITextField!
    private var contentEditableView: UIView!
    private var backgroundEditableView: UIView!
    private var hoursValueLabel: UILabel!
    private var minValueLabel: UILabel!
    
    private var isRenderHoursAndMinLabel = false
    private var hrsSelected = 0
    private var minSelected = 1
    private var tapGesture: TPTimePickerGesture!
    
    var minimumTime: TimeInterval = 60
    var maxHours = 49
    var maxMinutes = 60
    var didSelectTime: ((TimeInterval) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindObserver()
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bindObserver()
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !isRenderHoursAndMinLabel {
            isRenderHoursAndMinLabel = true
            addHoursAndMinLabel()
        }
    }
    
    func setTime(time: TimeInterval, animated: Bool) {
        minSelected = min(Int(time.truncatingRemainder(dividingBy: 3600) / 60), maxMinutes - 1)
        hrsSelected = min(Int(time / 3600), maxHours - 1)
        hoursValueLabel.text = String(format: "%d", hrsSelected)
        minValueLabel.text = String(format: "%02d", minSelected)
        pickerView.selectRow((49 * 500) + self.hrsSelected, inComponent: 0, animated: animated)
        pickerView.selectRow((60 * 500) + self.minSelected, inComponent: 1, animated: animated)
    }
    
    private func bindObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupView() {
        pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        
        addSubview(pickerView)
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pickerView]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["pickerView": pickerView!])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pickerView]-0-|", options: .init(rawValue: 0), metrics: nil, views: ["pickerView": pickerView!])
        addConstraints(hConstraint)
        addConstraints(vConstraint)
        
        tapGesture = TPTimePickerGesture(didTouch: {
            [weak self] type in
            guard let self = self else { return }
            switch type {
            case .all:
                self.enableEdit()
            case .cancel:
                self.disableEdit()
            case .hours:
                self.enableEditHours()
            case .minute:
                self.enableEditMin()
            }
        })
        
        tapGesture.delegate = self
        pickerView.addGestureRecognizer(tapGesture)
        
        minSelected = min(Int(minimumTime.truncatingRemainder(dividingBy: 3600) / 60), maxMinutes - 1)
        hrsSelected = min(Int(minimumTime / 3600), maxHours - 1)
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.pickerView.selectRow((self.maxHours * 500) + self.hrsSelected, inComponent: 0, animated: false)
            self.pickerView.selectRow((self.maxMinutes * 500) + self.minSelected, inComponent: 1, animated: false)
        }
        
        setupEditableView()
    }
    
    private func addHoursAndMinLabel() {
        let paddingLeft = (bounds.width - (WIDTH_COMPONENT * 2)) / 2.0
        let hoursLabel = UILabel()
        hoursLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        hoursLabel.text = NSLocalizedString("hours", comment: "")
        addSubview(hoursLabel)
        bringSubviewToFront(hoursLabel)
        hoursLabel.centerYAnchor.constraint(equalTo: pickerView.centerYAnchor, constant: 1).isActive = true
        hoursLabel.heightAnchor.constraint(equalToConstant: HEIGHT_COMPONENT).isActive = true
        hoursLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingLeft + WIDTH_COMPONENT_LABEL + 4).isActive = true
        
        let minLabel = UILabel()
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        minLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        minLabel.text = NSLocalizedString("min", comment: "")
        addSubview(minLabel)
        bringSubviewToFront(minLabel)
        minLabel.centerYAnchor.constraint(equalTo: pickerView.centerYAnchor, constant: 1).isActive = true
        minLabel.heightAnchor.constraint(equalToConstant: HEIGHT_COMPONENT).isActive = true
        minLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingLeft + WIDTH_COMPONENT + WIDTH_COMPONENT_LABEL + 8).isActive = true
    }
    
    private func setupEditableView() {
        textField = UITextField(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        textField.isHidden = true
        textField.keyboardType = .numberPad
        textField.addTarget(self, action: #selector(textFieldDidChanged(textField:)), for: .editingChanged)
        insertSubview(textField, at: 0)
        
        contentEditableView = UIView()
        contentEditableView.translatesAutoresizingMaskIntoConstraints = false
        contentEditableView.isHidden = true
        contentEditableView.backgroundColor = .white
        contentEditableView.layer.cornerRadius = 8
        contentEditableView.layer.masksToBounds = true
        contentEditableView.heightAnchor.constraint(equalToConstant: HEIGHT_COMPONENT + 2).isActive = true
        
        backgroundEditableView = UIView()
        backgroundEditableView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13, *) {
            backgroundEditableView.backgroundColor = .quaternarySystemFill
        }
        else {
            backgroundEditableView.backgroundColor = UIColor(red: 116/255, green: 116/255, blue: 128/255, alpha: 0.08)
        }
        
        backgroundEditableView.layer.cornerRadius = 8
        backgroundEditableView.layer.masksToBounds = true
        contentEditableView.addSubview(backgroundEditableView)
        contentEditableView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subView]-0-|", metrics: nil, views: ["subView": backgroundEditableView!]) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subView]-0-|", metrics: nil, views: ["subView": backgroundEditableView!])
        )
        
        let hoursView = UIView()
        hoursView.translatesAutoresizingMaskIntoConstraints = false
        hoursView.widthAnchor.constraint(equalToConstant: WIDTH_COMPONENT).isActive = true
        hoursValueLabel = UILabel()
        hoursValueLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursValueLabel.text = String(format: "%d", hrsSelected)
        hoursValueLabel.font = UIFont.systemFont(ofSize: 22)
        hoursValueLabel.textAlignment = .right
        hoursValueLabel.textColor = HIGHLIGHT_COLOR
        hoursView.addSubview(hoursValueLabel)
        hoursView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subView(\(WIDTH_COMPONENT_LABEL))]", metrics: nil, views: ["subView": hoursValueLabel!]) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subView]-0-|", metrics: nil, views: ["subView": hoursValueLabel!])
        )
        
        let minView = UIView()
        minView.translatesAutoresizingMaskIntoConstraints = false
        minView.widthAnchor.constraint(equalToConstant: WIDTH_COMPONENT).isActive = true
        minValueLabel = UILabel()
        minValueLabel.translatesAutoresizingMaskIntoConstraints = false
        minValueLabel.text = String(format: "%02d", minSelected)
        minValueLabel.font = UIFont.systemFont(ofSize: 22)
        minValueLabel.textAlignment = .right
        minValueLabel.textColor = HIGHLIGHT_COLOR
        minView.addSubview(minValueLabel)
        minView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subView(\(WIDTH_COMPONENT_LABEL))]", metrics: nil, views: ["subView": minValueLabel!]) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subView]-0-|", metrics: nil, views: ["subView": minValueLabel!])
        )
        
        let hStack = UIStackView(arrangedSubviews: [hoursView, minView])
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.spacing = 5
        contentEditableView.addSubview(hStack)
        hStack.centerXAnchor.constraint(equalTo: contentEditableView.centerXAnchor, constant: 0).isActive = true
        contentEditableView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subView]-0-|", metrics: nil, views: ["subView": hStack])
        )
        
        pickerView.addSubview(contentEditableView)
        contentEditableView.centerYAnchor.constraint(equalTo: pickerView.centerYAnchor, constant: 0).isActive = true
        pickerView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[subView]-8-|", metrics: nil, views: ["subView": contentEditableView!])
        )
    }
    
    @objc private func enableEdit() {
        pickerView.bringSubviewToFront(contentEditableView)
        contentEditableView.isHidden = false
        textField.becomeFirstResponder()
    }
    
    @objc private func enableEditHours() {
        pickerView.bringSubviewToFront(contentEditableView)
        textField.text = ""
        contentEditableView.isHidden = false
        hoursValueLabel.textColor = HIGHLIGHT_COLOR
        minValueLabel.textColor = .black
        textField.becomeFirstResponder()
    }
    
    @objc private func enableEditMin() {
        pickerView.bringSubviewToFront(contentEditableView)
        textField.text = ""
        contentEditableView.isHidden = false
        hoursValueLabel.textColor = .black
        minValueLabel.textColor = HIGHLIGHT_COLOR
        textField.becomeFirstResponder()
    }
    
    @objc private func disableEdit() {
        pickerView.bringSubviewToFront(contentEditableView)
        reloadPickerViewWithNewValueEdited()
        textField.text = ""
        contentEditableView.isHidden = true
        hoursValueLabel.textColor = HIGHLIGHT_COLOR
        minValueLabel.textColor = HIGHLIGHT_COLOR
        textField.resignFirstResponder()
    }
    
    @objc private func appWillEnterForeground() {
        pickerView.bringSubviewToFront(contentEditableView)
    }
    
    @objc private func textFieldDidChanged(textField: UITextField) {
        guard var text = textField.text else { return }
        if text.count > 4 {
            text = NSString(string: text).substring(with: NSRange(location: text.count - 4, length: 4))
            textField.text = text
        }
        
        let pickerHoursSelected = pickerView.selectedRow(inComponent: 0)
        let pickerMinSelected = pickerView.selectedRow(inComponent: 1)
        switch tapGesture.editableType {
        case .all:
            if text.isEmpty {
                minSelected = min(Int(minimumTime.truncatingRemainder(dividingBy: 3600) / 60), maxMinutes - 1)
                hrsSelected = min(Int(minimumTime / 3600), maxHours - 1)
                pickerView.selectRow((Int(pickerHoursSelected / maxHours) * maxHours) + hrsSelected, inComponent: 0, animated: true)
                pickerView.selectRow((Int(pickerMinSelected / maxMinutes) * maxMinutes) + minSelected, inComponent: 1, animated: true)
                hoursValueLabel.text = String(format: "%d", hrsSelected)
                minValueLabel.text = String(format: "%02d", minSelected)
            }
            else {
                var hrsValue = Int(Double(text)! / 100)
                var minValue = Int(text)! % 100
                if hrsValue > maxHours && minValue > maxMinutes {
                    minValue = hrsValue % 10
                    hrsValue = 0
                    textField.text = "\(minValue)"
                }
                else {
                    if hrsValue > maxHours - 1 {
                        hrsValue = hrsValue % 10
                    }
                }
                
                hrsSelected = min(hrsValue, maxHours - 1)
                minSelected = minValue
                if text.count > 2 {
                    pickerView.selectRow((Int(pickerHoursSelected / maxHours) * maxHours) + hrsSelected, inComponent: 0, animated: true)
                }
                
                if minSelected < maxMinutes {
                    pickerView.selectRow((Int(pickerMinSelected / maxMinutes) * maxMinutes) + minSelected, inComponent: 1, animated: true)
                }
                
                hoursValueLabel.text = String(format: "%d", hrsSelected)
                minValueLabel.text = String(format: "%02d", minSelected)
                handleDidSelectedTime()
                print("hours: \(hrsSelected) - min: \(minSelected)")
            }
        case .hours:
            if text.isEmpty {
                hrsSelected = min(Int(minimumTime / 3600), maxHours - 1)
            }
            else {
                var hrsValue = Int(text)! % 100
                if hrsValue > maxHours - 1 {
                    hrsValue = hrsValue % 10
                }
                
                hrsSelected = min(hrsValue, maxHours - 1)
            }
            
            pickerView.selectRow((Int(pickerHoursSelected / maxHours) * maxHours) + hrsSelected, inComponent: 0, animated: true)
            hoursValueLabel.text = String(format: "%d", hrsSelected)
            handleDidSelectedTime()
            print("hours: \(hrsSelected) - min: \(minSelected)")
        case .minute:
            if text.isEmpty {
                minSelected = min(Int(minimumTime.truncatingRemainder(dividingBy: 3600) / 60), maxMinutes - 1)
            }
            else {
                var minsValue = Int(text)! % 100
                if minsValue > maxMinutes - 1 {
                    minsValue = minsValue % 10
                }
                
                minSelected = min(minsValue, maxMinutes - 1)
            }
            
            pickerView.selectRow((Int(pickerMinSelected / maxMinutes) * maxMinutes) + minSelected, inComponent: 1, animated: true)
            minValueLabel.text = String(format: "%02d", minSelected)
            handleDidSelectedTime()
            print("hours: \(hrsSelected) - min: \(minSelected)")
        default:
            break
        }
    }
    
    @objc private func handleKeyboardWillHide() {
        disableEdit()
    }
    
    private func handleDidSelectedTime() {
        fixHrsAndMinSeleted()
        didSelectTime?(Double((hrsSelected * 3600) + (minSelected * 60)))
    }
    
    private func reloadPickerViewWithNewValueEdited() {
        fixHrsAndMinSeleted()
        let pickerHoursSelected = pickerView.selectedRow(inComponent: 0)
        let pickerMinSelected = pickerView.selectedRow(inComponent: 1)
        hoursValueLabel.text = String(format: "%d", hrsSelected)
        minValueLabel.text = String(format: "%02d", minSelected)
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.pickerView.selectRow((Int(pickerHoursSelected / self.maxHours) * self.maxHours) + self.hrsSelected, inComponent: 0, animated: false)
            self.pickerView.selectRow((Int(pickerMinSelected / self.maxMinutes) * self.maxMinutes) + self.minSelected, inComponent: 1, animated: false)
        }
    }
    
    private func fixHrsAndMinSeleted() {
        var mHrs = hrsSelected
        var mMins = minSelected
        if mMins > maxMinutes - 1 {
            mHrs = min(mHrs + (mMins / 60), maxHours - 1)
            if mHrs == maxHours - 1 {
                mMins = maxMinutes - 1
            }
            else {
                mMins = min(mMins % 60, maxMinutes - 1)
            }
        }
        
        hrsSelected = mHrs
        minSelected = mMins
    }
}

extension TPTimePicker: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return maxHours * 1000
        }
        else {
            return maxMinutes * 1000
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        debugPrint("scrolling - (\(component),\(row))")
        if tapGesture.editableType == .cancel && tapGesture.state != .possible {
            tapGesture.isEnabled = false
        }
        
        var contentView: UIView!
        if let mContentView = view {
            contentView = mContentView
        }
        else {
            contentView = UIView()
        }
        
        var label = contentView.viewWithTag(1991) as? UILabel
        if label == nil {
            label = UILabel()
            label!.font = UIFont.systemFont(ofSize: 22)
            label!.textAlignment = .right
            label!.tag = 1991
            label!.translatesAutoresizingMaskIntoConstraints = false
            label!.heightAnchor.constraint(equalToConstant: HEIGHT_COMPONENT).isActive = true
            label!.widthAnchor.constraint(equalToConstant: WIDTH_COMPONENT_LABEL).isActive = true
            contentView.addSubview(label!)
        }
        
        if component == 0 {
            label!.text = String(format: "%d", row % maxHours)
        }
        else {
            label!.text = String(format: "%02d", row % maxMinutes)
        }
        
        return contentView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        debugPrint("end scroll - (\(component),\(row))")
        tapGesture.isEnabled = true
        
        if component == 0 {
            hrsSelected = row % maxHours
        }
        else {
            minSelected = row % maxMinutes
        }
        
        let timeInterval: TimeInterval = Double(hrsSelected * 3600) + Double(minSelected * 60)
        if timeInterval < minimumTime {
            if component == 0 {
                hrsSelected = 0
                pickerView.selectRow((Int(row / maxHours) * maxHours), inComponent: 0, animated: true)
            }
            else {
                minSelected = 1
                pickerView.selectRow((Int(row / maxMinutes) * maxMinutes) + minSelected, inComponent: 1, animated: true)
            }
        }
        else {
            didSelectTime?(timeInterval)
        }
        
        hoursValueLabel.text = String(format: "%d", hrsSelected)
        minValueLabel.text = String(format: "%02d", minSelected)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return WIDTH_COMPONENT
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return HEIGHT_COMPONENT
    }
}

extension TPTimePicker: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//MARK: - HEXTimePickerGesture

fileprivate class TPTimePickerGesture: UIGestureRecognizer {
    var didTouchCompleted: ((TPTimePicker.EditableType) -> Void)
    
    private var beginPoint: CGPoint?
    private(set) var editableType: TPTimePicker.EditableType = .cancel
    
    init(didTouch: @escaping ((TPTimePicker.EditableType) -> Void)) {
        didTouchCompleted = didTouch
        super.init(target: nil, action: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let gestureView = view {
            beginPoint = touch.location(in: gestureView)
        }
        
        state = .began
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let beginPoint = beginPoint, let gestureView = view {
            let movePoint = touch.location(in: gestureView)
            let y = abs(movePoint.y - beginPoint.y)
            if y > 16 && editableType != .cancel {
                editableType = .cancel
                didTouchCompleted(editableType)
                
                print("================== end editing \(y)")
                state = .ended
                super.touchesMoved(touches, with: event)
                return
            }
        }
        
        state = .changed
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state != .ended else {
            super.touchesEnded(touches, with: event)
            return
        }
        
        if let touch = touches.first, let beginPoint = beginPoint, let gestureView = view {
            let endPoint = touch.location(in: gestureView)
            let paddingTop = (gestureView.bounds.height - HEIGHT_COMPONENT) / 2
            if abs(Int(beginPoint.x) - Int(endPoint.x)) < 8 &&
                abs(Int(beginPoint.y) - Int(endPoint.y)) < 8 &&
                endPoint.y >= paddingTop && endPoint.y <= (paddingTop + HEIGHT_COMPONENT) {
                switch editableType {
                case .cancel:
                    editableType = .all
                case .all, .hours, .minute:
                    let paddingLeft = (gestureView.bounds.width - (WIDTH_COMPONENT * 2)) / 2.0
                    if endPoint.x >= paddingLeft &&
                        endPoint.x < paddingLeft + WIDTH_COMPONENT {
                        editableType = .hours
                    }
                    
                    if endPoint.x >= paddingLeft + WIDTH_COMPONENT + 5 &&
                        endPoint.x <= paddingLeft + (WIDTH_COMPONENT * 2) + 5 {
                        editableType = .minute
                    }
                }
                
                didTouchCompleted(editableType)
            }
            else {
                if editableType != .cancel {
                    editableType = .cancel
                    didTouchCompleted(editableType)
                }
            }
        }
        else {
            if editableType != .cancel {
                editableType = .cancel
                didTouchCompleted(editableType)
            }
        }
        
        state = .ended
        super.touchesEnded(touches, with: event)
    }
    
    @objc fileprivate func handleKeyboardWillHide() {
        state = .possible
        editableType = .cancel
    }
}

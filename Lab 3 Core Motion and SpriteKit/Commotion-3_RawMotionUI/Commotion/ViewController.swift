//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    //MARK: class variables
    let activityManager = CMMotionActivityManager()  //to track user activities (walking, running, etc.)
    let pedometer = CMPedometer()    // for counting the steps
    let motion = CMMotionManager()   // for accessing raw motion data
    
    // observer property to update UI whenever totalSteps variable is about to change
    // total number of steps initially is 0
    var totalSteps: Float = 0.0 {
        
        // call before "totalSteps" is set to new value. "newtotalSteps" is passed as parameter to set new value for totalSteps
        willSet(newtotalSteps){
            
            // update UI on main thread
            DispatchQueue.main.async{
                // set value with subtle animation
                self.stepsSlider.setValue(newtotalSteps, animated: true)  // set value of stepsSlider to newtotalSteps with slight animation
                self.stepsLabel.text = "Steps: \(newtotalSteps)"   // update text of stepsLabel as new value of totalSteps
                
                //Module A
                self.updateRemainingSteps()  //to update the remaining steps from goal
            }
        }
    }
    
    
    
    // Module A: To set Daily goal persistently using UserDefaults (i.e.  value persists across app launches)
    var dailyGoal: Int {
        get {
            return UserDefaults.standard.integer(forKey: "dailyGoal")   //retrieve user daily goal
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dailyGoal")   //set the user daily goal value to "dailyGoal"
            updateRemainingSteps()
        }
    }
    
    
    //MARK: UI Elements
    @IBOutlet weak var stepsSlider: UISlider!   //slider to display step count
    @IBOutlet weak var stepsLabel: UILabel!     //label to display step count
    //@IBOutlet weak var isWalking: UILabel!      //label to display if user is walking/stationary
    
    // Module A
    @IBOutlet weak var todayStepsLabel: UILabel!          // Label to display today's step count
    @IBOutlet weak var yesterdayStepsLabel: UILabel!      // Label to display yesterday's step count
    @IBOutlet weak var dailyGoalTextField: UITextField!   //label for daily goal
    @IBOutlet weak var remainingStepsLabel: UILabel!      //label for remaining steps from goal
    @IBOutlet weak var activityLabel: UILabel!            // Label to display the current activity of the user
    
    
    //MARK: View Hierarchy
    //Three functions are called to start monitoring activity, pedometer updates, and motion updates
    override func viewDidLoad() {
        super.viewDidLoad()
        self.totalSteps = 0.0
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startMotionUpdates()
        
        // Module A: Fetch and display today's and yesterday's step counts
        self.fetchStepsForToday()
        self.fetchStepsForYesterday()
        
        // Module A: Display daily goal remaining steps lables
        self.dailyGoalTextField.delegate = self        //delegate for daily goal text field label
        self.dailyGoalTextField.text = "\(dailyGoal)"  //udpate the daily goal text field label with dailyGoal
        self.updateRemainingSteps()    //update the remaining steps
        
        // Module A: Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    //Module A: Function to fetch steps for a specific date. Closure "completion" is called with number of steps fetched (convenient way to handle errors)
    func fetchSteps(for date: Date, completion: @escaping (Int) -> Void) {
        let calendar = Calendar.current     //instance of current calender to get start and end of the day of give date
        let midnight = calendar.startOfDay(for: date)  //start of the day (midnight) for given date
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight)!  //start of next day (add 1 day to midnight)
        
        // call the query method on "pedometer" to get step count from midnight to next midnight
        // also takes closure with the results of "data" and "error"
        pedometer.queryPedometerData(from: midnight, to: nextMidnight) { (data, error) in
            
            // if error in fetching the step count
            if let error = error {
                print("Error fetching steps: \(error.localizedDescription)")  //error message
                completion(0)  // 0 step count for the date
                return
            }
            // if there is data and we have step count
            if let data = data {
                completion(data.numberOfSteps.intValue)   //get teh number of steps for the day
            } else {
                completion(0)   // 0 step count for the date
            }
        }
    }
    
    // Module A
    var todaySteps: Int = 0
    
    // Module A: Fetch and display today's step count
    func fetchStepsForToday() {
        
        // pass Date (i.e. current date and time) to fetchSteps method. Closure is executed once step count for today is fetched.
        fetchSteps(for: Date()) { steps in
            DispatchQueue.main.async {
                self.todayStepsLabel.text = "Today's Steps: \(steps)"   //update text label of "todayStespsLabel" with today's step count
                self.todaySteps = steps       // steps is the steps taken today so far
                self.updateRemainingSteps()   // update the remaining steps based on the goal set
            }
        }
    }
    
    
    // Module A: Fetch and display yesterday's step count
    func fetchStepsForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!   //calcualte date for yesterday
        
        // pass "yesterday" date to fetchSteps method. Closure is executed once step count for yesterday is fetched.
        fetchSteps(for: yesterday) { steps in
            DispatchQueue.main.async {
                self.yesterdayStepsLabel.text = "Yesterday's Steps: \(steps)"   //update text label of "yesterdayStepsLabel" with yesterday's step count
            }
        }
    }
    
    
    // Module A: Update the remaining steps label
    func updateRemainingSteps() {
        let remainingSteps = dailyGoal - todaySteps  //remaining steps = goal - steps taken till now
        if remainingSteps > 0 {
                remainingStepsLabel.text = "Steps to Goal: \(remainingSteps)" // Display remaining steps
        } else {
            remainingStepsLabel.text = "You met your goal!" // Display message for goal met
        }
    }
    
    
    //Module A: UITextFieldDelegate method to handle changes in the goal text field
    func textFieldDidEndEditing (_ textField: UITextField){
        
        // get goal text as from user, convert it into integer. If both "goalText" & "goal" are available
        if let goalText = textField.text, let goal = Int(goalText){
            dailyGoal = goal  //daily goal value is set
        }
    }
    
    //Module A: dismiss the keyboard once user presses return key after editing text field for goal
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  //dismiss keyboard once user is done editing the text field
        return true  //move to next action
    }
    
    // Handle keyboard will show
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardHeight / 2
            }
        }
    }
    
    // Handle keyboard will hide
    @objc func keyboardWillHide(notification: NSNotification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
}



// MARK: Extension for Raw Motion
extension ViewController{
    
    // MARK: Raw Motion Functions
    //check if device motion is available & start motion updates on main operation queue
    func startMotionUpdates(){
        
        //if device motion updates are available
        if self.motion.isDeviceMotionAvailable{
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: handleMotion)   //generate device motion updates & deliver to main queue for UI updates
        }
    }
    
    
    // Process device motion data to determine device orientation and rotate "isWalking" image to match the orientation
    func handleMotion(_ motionData: CMDeviceMotion?, error: Error?){
        
        // if we have gravity property from "motionData"
        if let gravity = motionData?.gravity {
            let rotation = atan2(gravity.x, gravity.y) - Double.pi   //compute rotation angle based on gravity vectors x and y
            //self.isWalking.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))  //apply calculated rotation to "isWalking" image
        }
    }
}


// MARK: Extension for Pedometer and Activity
extension ViewController{
    // ========Pedometer Functions========
    
    
    // start pedometer updates to count steps
    func startPedometerMonitoring(){
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startUpdates(from: Date(),withHandler: self.handlePedometer )   //start pedometer updates as soon as this method gets called
        } else {
            print ("Step counting is not available.")
        }
    }
    
    
    //process step count data from pedometer & update steps on slider
    func handlePedometer(_ pedData:CMPedometerData?, error:Error?){
        
        // if pedData contains valid step count data
        if let steps = pedData?.numberOfSteps {
            self.totalSteps = steps.floatValue   //update totalSteps with the step count
            print("Updated total steps: \(steps.floatValue)")
            self.fetchStepsForToday()
        } else if let error = error {
            print("Error updating pedometer: \(error.localizedDescription)")
        }
    }
    
    // ========Activity Functions========
    
    // start activity updates to monitor user physical activity
    func startActivityMonitoring(){
        
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            
            //start activity updates & deliver to main queue for UI udpates
            self.activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: self.handleActivity)
        } else {
            print("Activity monitoring is not available.")
        }
    }
    
    
    //update UI based on user's current activity detected by the device
    func handleActivity(_ activity:CMMotionActivity?)->Void{
        
        // safely unwrap the activity parameter
        if let unwrappedActivity = activity {
            
            // update text label isWalking as with information about user's activity (i.e. Walking)
            DispatchQueue.main.async{
                //self.isWalking.text = "Walking: \(unwrappedActivity.walking)\n Still: \(unwrappedActivity.stationary)"
                
                //Module A: Use "unwrappedActivity" object to classify detected activity
                if unwrappedActivity.unknown {
                    self.activityLabel.text = "Activity: Unknown 🤷‍♂️"
                } else if unwrappedActivity.stationary {
                    self.activityLabel.text = "Activity: Still 🧘‍♂️"
                } else if unwrappedActivity.walking {
                    self.activityLabel.text = "Activity: Walking 🚶‍♂️"
                } else if unwrappedActivity.running {
                    self.activityLabel.text = "Activity: Running 🏃‍♂️"
                } else if unwrappedActivity.cycling {
                    self.activityLabel.text = "Activity: Cycling 🚴‍♂️"
                } else if unwrappedActivity.automotive {
                    self.activityLabel.text = "Activity: Driving 🚗"
                } else {
                    self.activityLabel.text = "Acvitiy: Unknown 🤷‍♂️"
                }
            }
        }
    }
}

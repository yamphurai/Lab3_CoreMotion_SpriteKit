
import CoreMotion
import Foundation

protocol MotionModelDelegate: AnyObject {
    func didUpdateSteps(todaySteps: Int, yesterdaySteps: Int)
    func didUpdateActivity(walking: Bool, stationary: Bool)
}

class MotionModel {


}

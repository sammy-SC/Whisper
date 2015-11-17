import UIKit

let shout = ShoutView()

public func Shout(announcement: Announcement, to: UIViewController) {
  shout.craft(announcement, to: to)
}

public class ShoutView: UIView {

  public struct Dimensions {
    public static let height: CGFloat = 80
    public static let width: CGFloat = UIScreen.mainScreen().bounds.width
    public static let indicatorHeight: CGFloat = 6
    public static let indicatorWidth: CGFloat = 50
    public static let imageSize: CGFloat = 48
    public static let imageOffset: CGFloat = 18
    public static let textOffset: CGFloat = 75
  }

  public lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.background
    view.alpha = 0.98

    return view
    }()

  public lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
    return blurView
    }()

  public lazy var gestureContainer: UIView = {
    let view = UIView()
    view.userInteractionEnabled = true

    return view
    }()

  public lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.userInteractionEnabled = true

    return view
    }()

  public lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.imageSize / 2
    imageView.clipsToBounds = true
    imageView.contentMode = .ScaleAspectFill
    imageView.backgroundColor = UIColor.blackColor()

    return imageView
    }()

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.title
    label.tintColor = ColorList.Shout.title
    label.numberOfLines = 1

    return label
    }()

  public lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.subtitle
    label.tintColor = ColorList.Shout.subtitle
    label.numberOfLines = 1

    return label
    }()

  public lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: "handleTapGestureRecognizer")

    return gesture
    }()

  public lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: "handlePanGestureRecognizer")

    return gesture
    }()

  public var announcement: Announcement?
  public var displayTimer = NSTimer()
  public var panGestureActive = false
  public var shouldSilent = false

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundView)
    backgroundView.addSubview(blurView)
    [indicatorView, gestureContainer, imageView, titleLabel, subtitleLabel].forEach {
      blurView.addSubview($0) }

    clipsToBounds = true
    userInteractionEnabled = true

    addGestureRecognizer(tapGestureRecognizer)
    gestureContainer.addGestureRecognizer(panGestureRecognizer)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  public func craft(announcement: Announcement, to: UIViewController) {
    panGestureActive = false
    shouldSilent = false
    configureView(announcement)
    shout(to: to)
  }

  public func configureView(announcement: Announcement) {
    self.announcement = announcement
    imageView.image = announcement.image
    titleLabel.text = "Ramon Gilabert"
    subtitleLabel.text = "Just commented a post in the Wall that you are following"
    [titleLabel, subtitleLabel].forEach {
      $0.sizeToFit()
    }

    displayTimer.invalidate()
    displayTimer = NSTimer.scheduledTimerWithTimeInterval(announcement.duration,
      target: self, selector: "displayTimerDidFire", userInfo: nil, repeats: false)
    setupFrames()
  }

  public func shout(to controller: UIViewController) {
    guard let controller = controller.navigationController else { fatalError("The controller must contain a navigation bar") }

    controller.view.addSubview(self)

    frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 0)
    UIView.animateWithDuration(0.35, animations: {
      self.frame.size.height = Dimensions.height
    })
  }

  // MARK: - Setup

  public func setupFrames() {
    backgroundView.frame = CGRect(x: 0, y: 0, width: Dimensions.width, height: Dimensions.height)
    blurView.frame = backgroundView.bounds
    gestureContainer.frame = CGRect(x: 0, y: Dimensions.height - 20, width: Dimensions.width, height: 20)
    indicatorView.frame = CGRect(x: (Dimensions.width - Dimensions.indicatorWidth) / 2,
      y: Dimensions.height - Dimensions.indicatorHeight - 5, width: Dimensions.indicatorWidth, height: Dimensions.indicatorHeight)
    imageView.frame = CGRect(x: Dimensions.imageOffset, y: (Dimensions.height - Dimensions.imageSize) / 2 + 5,
      width: Dimensions.imageSize, height: Dimensions.imageSize)
    titleLabel.frame.origin = CGPoint(x: Dimensions.textOffset, y: imageView.frame.origin.y + 3)
    subtitleLabel.frame.origin = CGPoint(x: Dimensions.textOffset, y: CGRectGetMaxY(titleLabel.frame) + 2.5)

    [titleLabel, subtitleLabel].forEach {
      $0.frame.size.width = Dimensions.width - Dimensions.imageSize - (Dimensions.imageOffset * 2) }
  }

  // MARK: - Actions

  public func silent() {
    UIView.animateWithDuration(0.35, animations: {
      self.frame.size.height = 0
      }, completion: { finished in
        self.removeFromSuperview()
    })
  }

  // MARK: - Timer methods

  public func displayTimerDidFire() {
    shouldSilent = true

    guard !panGestureActive else { return }
    silent()
  }

  // MARK: - Gesture methods

  public func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }

  public func handlePanGestureRecognizer() {
    let translation = panGestureRecognizer.translationInView(self)
    var duration: NSTimeInterval = 0

    if panGestureRecognizer.state == .Changed || panGestureRecognizer.state == .Began {
      panGestureActive = true
      if translation.y >= 12 {
        frame.size.height = Dimensions.height + 12 + (translation.y) / 25
      } else {
        frame.size.height = Dimensions.height + translation.y
      }
    } else {
      panGestureActive = false
      let height = translation.y < -5 || shouldSilent ? 0 : Dimensions.height

      duration = 0.2
      UIView.animateWithDuration(duration, animations: {
        self.frame.size.height = height
        }, completion: { _ in if translation.y < -5 { self.removeFromSuperview() }})
    }

    UIView.animateWithDuration(duration, animations: {
      self.backgroundView.frame.size.height = self.frame.height
      self.blurView.frame.size.height = self.frame.height
      self.gestureContainer.frame.origin.y = self.frame.height - 20
      self.indicatorView.frame.origin.y = self.frame.height - Dimensions.indicatorHeight - 5
    })
  }
}

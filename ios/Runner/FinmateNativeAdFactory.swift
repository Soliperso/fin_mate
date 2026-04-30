import Foundation
import GoogleMobileAds
import google_mobile_ads

class FinmateNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {
        let adView = GADNativeAdView()
        adView.backgroundColor = .systemBackground

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        headlineLabel.numberOfLines = 1
        headlineLabel.text = nativeAd.headline
        adView.headlineView = headlineLabel

        // Body
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = UIColor.systemGray
        bodyLabel.numberOfLines = 2
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        adView.bodyView = bodyLabel

        // Icon
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        if let icon = nativeAd.icon {
            iconView.image = icon.image
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
        adView.iconView = iconView

        // CTA button
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        ctaButton.backgroundColor = UIColor(red: 0.125, green: 0.502, blue: 0.553, alpha: 1)
        ctaButton.layer.cornerRadius = 6
        ctaButton.isHidden = nativeAd.callToAction == nil
        adView.callToActionView = ctaButton
        adView.callToActionView?.isUserInteractionEnabled = false

        // Layout
        let iconSize: CGFloat = 40
        let padding: CGFloat = 12
        let ctaWidth: CGFloat = 80

        iconView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(iconView)
        adView.addSubview(headlineLabel)
        adView.addSubview(bodyLabel)
        adView.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: padding),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: padding),
            headlineLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: padding),
            headlineLabel.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -padding),

            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -padding),

            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -padding),
            ctaButton.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            ctaButton.widthAnchor.constraint(equalToConstant: ctaWidth),
            ctaButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}

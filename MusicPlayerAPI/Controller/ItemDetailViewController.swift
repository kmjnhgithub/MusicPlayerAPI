//
//  ItemDetailViewController.swift
//  MusicPlayerAPI
//
//  Created by mike liu on 2023/5/24.
//

import UIKit
import AVFoundation
import Kingfisher

class ItemDetailViewController: UIViewController, AVAudioPlayerDelegate {
    
    public var items: [StoreItem] = []
    public var position: Int = 0
    public var player: AVAudioPlayer?
    let nextButton = UIButton()
    let backButton = UIButton()

    @IBOutlet weak var holder: UIView!
    
    // user Interface elements
    private let albumImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let shadowView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let artistNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let albumNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let songNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica-Bold", size:20)
        label.numberOfLines = 0 // line wrap
        return label
    }()
    
    private let volumeLowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "speaker.minus.fill") // 音量低的icon
        return imageView
    }()

    private let volumeHighImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "speaker.plus.fill") // 音量高的icon
        return imageView
    }()
    
    let playPauseButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if holder.subviews.count == 0 {
            configure()
        }
    }
    
    func configure() {
        // set up player
        let item = items[position]
        let previewUrl = item.previewUrl
        
        if let cachedURL = getCachedURL(for: previewUrl) {
            // Use the cached file
            preparePlayer(with: cachedURL)
        } else {
            // Download the file
            downloadFile(from: previewUrl) { [weak self] (url, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Download error: \(error)")
                } else if let url = url {
                    self.preparePlayer(with: url)
                }
            }
        }

        
        // set up user interface elements
        
        // shadow frame
        shadowView.frame = CGRect(x: 10, y: 10, width: holder.frame.size.width-20, height: holder.frame.size.width-20)
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 10
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 10).cgPath
        shadowView.layer.masksToBounds = false
        shadowView.backgroundColor = .clear
        holder.addSubview(shadowView)
        
        // album cover
        albumImageView.frame = CGRect(x: 10, y: 10, width: holder.frame.size.width-20, height: holder.frame.size.width-20)
        albumImageView.kf.setImage(with: item.artworkUrl100, placeholder: UIImage(systemName: "music.note"))
        albumImageView.layer.cornerRadius = 10
        albumImageView.layer.masksToBounds = true
        shadowView.addSubview(albumImageView)
        
        shadowView.addSubview(albumImageView)
        holder.addSubview(albumImageView)
        
        
        // labels: Song name, album, artist
//        albumNameLabel.frame = CGRect(x: 10, y: albumImageView.frame.size.height + 10, width: holder.frame.size.width-20, height: 70)
        songNameLabel.frame = CGRect(x: 10, y: albumImageView.frame.size.height + 10 , width: holder.frame.size.width-20, height: 105)
        artistNameLabel.frame = CGRect(x: 10, y: albumImageView.frame.size.height + 40, width: holder.frame.size.width-20, height: 105)
        
        songNameLabel.text = item.trackName
//        albumNameLabel.text = song.albumName
        artistNameLabel.text = item.artistName

        
//        holder.addSubview(albumNameLabel)
        holder.addSubview(songNameLabel)
        holder.addSubview(artistNameLabel)
        
        // Player controls
        
        
        
        // Frame
        let yPosition = artistNameLabel.frame.origin.y + 130
        let size: CGFloat = 50
        playPauseButton.frame = CGRect(x: (holder.frame.size.width - size) / 2.0, y: yPosition, width: size, height: size)
        nextButton.frame = CGRect(x: holder.frame.size.width - size - 70, y: yPosition, width: size, height: size)
        backButton.frame = CGRect(x: 70, y: yPosition, width: size, height: size)
        
        // Add actions
        playPauseButton.addTarget(self, action: #selector(didTapPlayPauseButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        
        
        // Style
        playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        backButton.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        nextButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        
        playPauseButton.tintColor = .black
        backButton.tintColor = .black
        nextButton.tintColor = .black
        
        holder.addSubview(playPauseButton)
        holder.addSubview(backButton)
        holder.addSubview(nextButton)
        
        // slider
        let slider = UISlider(frame: CGRect(x: 50, y: holder.frame.size.height-60, width: holder.frame.size.width-100, height: 50))
        holder.addSubview(slider)
        slider.value = 0.3
        slider.addTarget(self, action: #selector(didSlideSlider(_:)), for: .valueChanged)
        holder.addSubview(slider)
        

        // volume low icon
        volumeLowImageView.frame = CGRect(x: slider.frame.origin.x - 30, y: slider.center.y - 10, width: 20, height: 20)
        holder.addSubview(volumeLowImageView)

        // volume high icon
        volumeHighImageView.frame = CGRect(x: slider.frame.origin.x + slider.frame.size.width + 10, y: slider.center.y - 10, width: 20, height: 20)
        holder.addSubview(volumeHighImageView)

    }
    
    func preparePlayer(with url: URL) {
        do {
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.delegate = self
            
            guard let player = self.player else {
                print("player is nil")
                return
            }
            
            player.volume = 0.3
            
            player.play()
        }
        catch {
            print("error occurred")
        }
    }
    
    func getCachedURL(for url: URL) -> URL? {
        let tempDirURL = FileManager.default.temporaryDirectory
        let destinationURL = tempDirURL.appendingPathComponent(url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return destinationURL
        } else {
            return nil
        }
    }
    
    func downloadFile(from url: URL, completion: @escaping (URL?, Error?) -> Void) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { (urlOrNil, responseOrNil, errorOrNil) in
            if let error = errorOrNil {
                completion(nil, error)
            } else if let tempURL = urlOrNil {
                let tempDirURL = FileManager.default.temporaryDirectory
                let destinationURL = tempDirURL.appendingPathComponent(url.lastPathComponent)
                
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                    completion(destinationURL, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
        downloadTask.resume()
    }
    
    @objc func didTapBackButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (_) in
            UIView.animate(withDuration: 0.1, animations: {
                self.backButton.transform = CGAffineTransform.identity
            })
        }
        if position > 0 {
            position = position - 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
    }
    
    @objc func didTapNextButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (_) in
            UIView.animate(withDuration: 0.1, animations: {
                self.nextButton.transform = CGAffineTransform.identity
            })
        }
        if position < (items.count - 1) {
            position = position + 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
    }
    
    @objc func didTapPlayPauseButton() {
        if player?.isPlaying == true {
            player?.pause()
            // show play button
            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            
            // shrink image
            UIView.animate(withDuration: 0.2) {
                self.albumImageView.frame = CGRect(x: 30, y: 30, width: self.holder.frame.size.width-60, height: self.holder.frame.size.width-60)
                
                self.shadowView.frame = CGRect(x: self.shadowView.frame.origin.x + 15,
                                               y: self.shadowView.frame.origin.y + 15,
                                               width: self.shadowView.frame.size.width - 30,
                                               height: self.shadowView.frame.size.height - 30)
                self.shadowView.layer.shadowPath = UIBezierPath(roundedRect: self.shadowView.bounds, cornerRadius: 10).cgPath
                self.shadowView.layer.shadowRadius = 10
            }
        } else {
            player?.play()
            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // increase image size
            UIView.animate(withDuration: 0.2) {
                self.albumImageView.frame = CGRect(x: 10, y: 10, width: self.holder.frame.size.width-20, height: self.holder.frame.size.width - 20)
                
                self.shadowView.frame = CGRect(x: 10, y: 10, width: self.holder.frame.size.width-20, height: self.holder.frame.size.width - 20)
                self.shadowView.layer.shadowPath = UIBezierPath(roundedRect: self.shadowView.bounds, cornerRadius: 10).cgPath
                self.shadowView.layer.shadowRadius = 10
            }
        }
    }
    
    @objc func didSlideSlider(_ slider: UISlider) {
        let value = slider.value
        player?.volume = value
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            player.stop()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if position < (items.count - 1) {
            position += 1
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
    }
}

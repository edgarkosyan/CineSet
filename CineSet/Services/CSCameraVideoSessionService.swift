//
//  CSCameraVideoSessionService.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import AVFoundation
import Foundation

struct CSCameraCapabilities: Sendable {
    let resolutionOptions: [CSCameraResolution]
    let fpsOptions: [Int]
    let shutterOptions: [Int]
    let isoOptions: [Float]
    let supportsLowLightBoost: Bool
}

struct CSCameraAppliedSettings: Sendable {
    let resolution: CSCameraResolution
    let fps: Int
    let shutter: Int
    let iso: Float
    let manualControls: CSCameraManualControls
}

protocol CSCameraVideoSessionServicing {
    var session: AVCaptureSession { get }

    func configure(
        applying settings: CSCameraAppliedSettings,
        completion: (@MainActor (CSCameraCapabilities, CSCameraAppliedSettings) -> Void)?
    )
    func stop()

    func updateResolution(
        _ resolution: CSCameraResolution,
        settings: CSCameraAppliedSettings,
        completion: (@MainActor (CSCameraCapabilities, CSCameraAppliedSettings) -> Void)?
    )
    func updateFPS(_ fps: Int, resolution: CSCameraResolution)
    func updateManualControls(_ settings: CSCameraAppliedSettings)
    func focus(at devicePoint: CGPoint, settings: CSCameraAppliedSettings)
    func readMeteredExposure(completion: (@MainActor (Int, Float) -> Void)?)
}

final class CSCameraVideoSessionService: NSObject, CSCameraVideoSessionServicing {

    static let fpsCandidates = [24, 25, 30, 50, 60, 120, 240]
    static let shutterCandidates = [
        25, 30, 40, 50, 60, 80, 100, 120,
        160, 200, 250, 320, 400, 500,
        800, 1000, 1600, 2000, 4000
    ]
    static let isoCandidates: [Float] = [50, 100, 200, 400, 800, 1600, 3200]

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDevice: AVCaptureDevice?
    private var isConfigured = false

    nonisolated override init() {
        super.init()
    }
    
    func configure(
        applying settings: CSCameraAppliedSettings,
        completion: (@MainActor (CSCameraCapabilities, CSCameraAppliedSettings) -> Void)? = nil
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.configureSessionIfNeeded()

            guard let device = self.videoDevice else {
                self.deliverCompletion(completion, capabilities: .empty, applied: settings)
                return
            }

            let applied = self.resolveAndApply(settings, on: device)
            self.startSessionIfNeeded()

            let capabilities = Self.capabilities(for: device, resolution: applied.resolution)
            self.deliverCompletion(completion, capabilities: capabilities, applied: applied)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func updateResolution(
        _ resolution: CSCameraResolution,
        settings: CSCameraAppliedSettings,
        completion: (@MainActor (CSCameraCapabilities, CSCameraAppliedSettings) -> Void)? = nil
    ) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }

            let updated = CSCameraAppliedSettings(
                resolution: resolution,
                fps: settings.fps,
                shutter: settings.shutter,
                iso: settings.iso,
                manualControls: settings.manualControls
            )
            let applied = self.resolveAndApply(updated, on: device)
            let capabilities = Self.capabilities(for: device, resolution: applied.resolution)
            self.deliverCompletion(completion, capabilities: capabilities, applied: applied)
        }
    }

    func updateFPS(_ fps: Int, resolution: CSCameraResolution) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            self.setResolutionAndFPS(resolution: resolution, fps: fps, on: device)
        }
    }

    func updateManualControls(_ settings: CSCameraAppliedSettings) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            self.applyManualControls(settings, on: device)
        }
    }

    func focus(at devicePoint: CGPoint, settings: CSCameraAppliedSettings) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }
            self.applyFocus(at: devicePoint, settings: settings, on: device)
        }
    }

    func readMeteredExposure(completion: (@MainActor (Int, Float) -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDevice else { return }

            let shutter = Self.shutterDenominator(from: device.exposureDuration)
            let iso = device.iso
            self.deliverMeteredExposure(completion, shutter: shutter, iso: iso)
        }
    }

    // MARK: - Session setup

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        videoDevice = device
        session.addInput(input)
        isConfigured = true

        session.commitConfiguration()
    }

    private func startSessionIfNeeded() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    private func deliverCompletion(
        _ completion: (@MainActor (CSCameraCapabilities, CSCameraAppliedSettings) -> Void)?,
        capabilities: CSCameraCapabilities,
        applied: CSCameraAppliedSettings
    ) {
        guard let completion else { return }

        Task { @MainActor in
            completion(capabilities, applied)
        }
    }

    private func deliverMeteredExposure(
        _ completion: (@MainActor (Int, Float) -> Void)?,
        shutter: Int,
        iso: Float
    ) {
        guard let completion else { return }

        Task { @MainActor in
            completion(shutter, iso)
        }
    }

    static func shutterDenominator(from duration: CMTime) -> Int {
        guard duration.value > 0 else { return 0 }
        return max(Int(round(Double(duration.timescale) / Double(duration.value))), 1)
    }

    // MARK: - Resolve + apply

    @discardableResult
    private func resolveAndApply(_ settings: CSCameraAppliedSettings, on device: AVCaptureDevice) -> CSCameraAppliedSettings {
        let resolutionOptions = Self.supportedResolutionOptions(for: device)
        let resolution = Self.nearestSupported(settings.resolution, in: resolutionOptions, default: .p1080)

        let fpsOptions = Self.supportedFPSOptions(for: device, resolution: resolution)
        let fps = Self.nearestSupported(settings.fps, in: fpsOptions, default: 30)

        setResolutionAndFPS(resolution: resolution, fps: fps, on: device)

        let shutterOptions = Self.supportedShutterOptions(for: device)
        let isoOptions = Self.supportedISOOptions(for: device)
        let shutter = Self.nearestSupported(settings.shutter, in: shutterOptions, default: 50)
        let iso = Self.nearestSupported(settings.iso, in: isoOptions, default: 100)

        let manualControls = settings.manualControls
        let applied = CSCameraAppliedSettings(
            resolution: resolution,
            fps: fps,
            shutter: shutter,
            iso: iso,
            manualControls: manualControls
        )

        applyManualControls(applied, on: device)
        return applied
    }

    private func applyManualControls(_ settings: CSCameraAppliedSettings, on device: AVCaptureDevice) {
        let controls = settings.manualControls

        do {
            try device.lockForConfiguration()

            device.automaticallyAdjustsVideoHDREnabled = controls.isHDRAutoAdjustmentEnabled

            if device.isLowLightBoostSupported {
                device.automaticallyEnablesLowLightBoostWhenAvailable = controls.isLowLightBoostEnabled
            }

            applyFocusMode(controls.focusMode, on: device)
            device.isSubjectAreaChangeMonitoringEnabled =
                controls.exposureMode == .auto || controls.focusMode == .auto

            switch controls.exposureMode {
            case .auto:
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
            case .manual:
                applyCustomExposure(shutter: settings.shutter, iso: settings.iso, on: device)
            }

            applyWhiteBalance(controls, on: device)

            device.unlockForConfiguration()
        } catch {
            print("Failed to apply manual controls:", error)
        }
    }

    private func applyFocusMode(_ mode: CSCameraControlMode, on device: AVCaptureDevice) {
        switch mode {
        case .auto:
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
        case .manual:
            if device.isFocusModeSupported(.locked) {
                device.focusMode = .locked
            }
        }
    }

    private func applyFocus(
        at devicePoint: CGPoint,
        settings: CSCameraAppliedSettings,
        on device: AVCaptureDevice
    ) {
        let point = CGPoint(
            x: min(max(devicePoint.x, 0), 1),
            y: min(max(devicePoint.y, 0), 1)
        )

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }

            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }

            device.unlockForConfiguration()
        } catch {
            print("Failed to focus at point:", error)
        }
    }

    private func applyCustomExposure(shutter: Int, iso: Float, on device: AVCaptureDevice) {
        guard Self.supportsShutter(denominator: shutter, on: device) else {
            print("Shutter 1/\(shutter) is not supported on this device.")
            return
        }

        let duration = CMTime(value: 1, timescale: CMTimeScale(shutter))
        let clampedDuration = Self.clampTime(
            duration,
            min: device.activeFormat.minExposureDuration,
            max: device.activeFormat.maxExposureDuration
        )
        let clampedISO = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)

        device.setExposureModeCustom(
            duration: clampedDuration,
            iso: clampedISO,
            completionHandler: nil
        )
    }

    private func applyWhiteBalance(_ controls: CSCameraManualControls, on device: AVCaptureDevice) {
        switch controls.whiteBalanceMode {
        case .auto:
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        case .manual:
            guard device.isWhiteBalanceModeSupported(.locked) else { return }

            let temperature = min(
                max(controls.whiteBalanceTemperature, CSCameraManualControls.temperatureRange.lowerBound),
                CSCameraManualControls.temperatureRange.upperBound
            )
            let tint = min(
                max(controls.whiteBalanceTint, CSCameraManualControls.tintRange.lowerBound),
                CSCameraManualControls.tintRange.upperBound
            )

            let values = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                temperature: temperature,
                tint: tint
            )
            var gains = device.deviceWhiteBalanceGains(for: values)
            gains = Self.normalizedWhiteBalanceGains(gains, for: device)

            device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
        }
    }

    // MARK: - Capabilities

    static func capabilities(for device: AVCaptureDevice, resolution: CSCameraResolution) -> CSCameraCapabilities {
        CSCameraCapabilities(
            resolutionOptions: supportedResolutionOptions(for: device),
            fpsOptions: supportedFPSOptions(for: device, resolution: resolution),
            shutterOptions: supportedShutterOptions(for: device),
            isoOptions: supportedISOOptions(for: device),
            supportsLowLightBoost: device.isLowLightBoostSupported
        )
    }

    private static func supportedResolutionOptions(for device: AVCaptureDevice) -> [CSCameraResolution] {
        CSCameraResolution.allCases.filter { resolution in
            device.formats.contains { format in
                formatMatchesResolution(format, resolution: resolution)
                    && fpsCandidates.contains { formatSupportsFPSApplication($0, format: format) }
            }
        }
    }

    private static func supportedFPSOptions(for device: AVCaptureDevice, resolution: CSCameraResolution) -> [Int] {
        fpsCandidates.filter { formatSupporting(fps: $0, resolution: resolution, on: device) != nil }
    }

    private static func supportedShutterOptions(for device: AVCaptureDevice) -> [Int] {
        shutterCandidates.filter { supportsShutter(denominator: $0, on: device) }
    }

    private static func supportedISOOptions(for device: AVCaptureDevice) -> [Float] {
        isoCandidates.filter { $0 >= device.activeFormat.minISO && $0 <= device.activeFormat.maxISO }
    }

    private static func nearestSupported<T: Comparable>(
        _ value: T,
        in options: [T],
        default defaultValue: T
    ) -> T {
        guard !options.isEmpty else { return defaultValue }
        if options.contains(value) { return value }
        return options.min(by: { absComparable($0, value) < absComparable($1, value) }) ?? defaultValue
    }

    private static func absComparable<T: Comparable>(_ lhs: T, _ rhs: T) -> Int {
        if let lhs = lhs as? Int, let rhs = rhs as? Int {
            return abs(lhs - rhs)
        }
        if let lhs = lhs as? Float, let rhs = rhs as? Float {
            return Int(abs(lhs - rhs))
        }
        if let lhs = lhs as? CSCameraResolution, let rhs = rhs as? CSCameraResolution {
            return abs(lhs.rawValue - rhs.rawValue)
        }
        return 0
    }

    private static func normalizedWhiteBalanceGains(
        _ gains: AVCaptureDevice.WhiteBalanceGains,
        for device: AVCaptureDevice
    ) -> AVCaptureDevice.WhiteBalanceGains {
        var normalized = gains
        let maxGain = device.maxWhiteBalanceGain
        normalized.redGain = max(1.0, min(gains.redGain, maxGain))
        normalized.greenGain = max(1.0, min(gains.greenGain, maxGain))
        normalized.blueGain = max(1.0, min(gains.blueGain, maxGain))
        return normalized
    }

    // MARK: - Apply settings

    @discardableResult
    private func setResolutionAndFPS(
        resolution: CSCameraResolution,
        fps: Int,
        on device: AVCaptureDevice
    ) -> Bool {
        guard let format = Self.formatSupporting(fps: fps, resolution: resolution, on: device) else {
            print("Resolution \(resolution.title) at \(fps) fps is not supported on this device.")
            return false
        }

        do {
            try device.lockForConfiguration()

            if device.activeFormat != format {
                device.activeFormat = format
            }

            let duration = CMTime(value: 1, timescale: CMTimeScale(fps))
            guard Self.formatSupportsFrameDuration(duration, format: device.activeFormat) else {
                device.unlockForConfiguration()
                print("Frame duration for \(fps) fps is not supported on the active format.")
                return false
            }

            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
            return true
        } catch {
            print("Failed to update resolution/FPS:", error)
        }
        return false
    }

    // MARK: - Format helpers

    private static func formatSupporting(
        fps: Int,
        resolution: CSCameraResolution,
        on device: AVCaptureDevice
    ) -> AVCaptureDevice.Format? {
        let duration = CMTime(value: 1, timescale: CMTimeScale(fps))

        return device.formats
            .filter { format in
                formatMatchesResolution(format, resolution: resolution)
                    && formatSupportsFPSApplication(fps, format: format, duration: duration)
            }
            .min(by: { resolutionDistance($0, resolution: resolution) < resolutionDistance($1, resolution: resolution) })
    }

    private static func formatSupportsFPSApplication(
        _ fps: Int,
        format: AVCaptureDevice.Format,
        duration: CMTime? = nil
    ) -> Bool {
        let frameDuration = duration ?? CMTime(value: 1, timescale: CMTimeScale(fps))
        return format.videoSupportedFrameRateRanges.contains { range in
            range.minFrameRate <= Double(fps)
                && Double(fps) <= range.maxFrameRate
                && CMTimeCompare(frameDuration, range.minFrameDuration) >= 0
                && CMTimeCompare(frameDuration, range.maxFrameDuration) <= 0
        }
    }

    private static func formatSupportsFrameDuration(_ duration: CMTime, format: AVCaptureDevice.Format) -> Bool {
        format.videoSupportedFrameRateRanges.contains { range in
            CMTimeCompare(duration, range.minFrameDuration) >= 0
                && CMTimeCompare(duration, range.maxFrameDuration) <= 0
        }
    }

    private static func formatMatchesResolution(
        _ format: AVCaptureDevice.Format,
        resolution: CSCameraResolution
    ) -> Bool {
        abs(formatShortEdge(format) - resolution.targetShortEdge) <= resolutionTolerance(for: resolution)
    }

    private static func resolutionDistance(
        _ format: AVCaptureDevice.Format,
        resolution: CSCameraResolution
    ) -> Int {
        abs(formatShortEdge(format) - resolution.targetShortEdge)
    }

    private static func resolutionTolerance(for resolution: CSCameraResolution) -> Int {
        max(80, resolution.targetShortEdge / 8)
    }

    private static func formatShortEdge(_ format: AVCaptureDevice.Format) -> Int {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        return Int(min(dimensions.width, dimensions.height))
    }

    private static func supportsShutter(denominator: Int, on device: AVCaptureDevice) -> Bool {
        let duration = CMTime(value: 1, timescale: CMTimeScale(denominator))
        let clamped = clampTime(
            duration,
            min: device.activeFormat.minExposureDuration,
            max: device.activeFormat.maxExposureDuration
        )
        return CMTimeCompare(clamped, duration) == 0
    }

    private static func clampTime(_ time: CMTime, min minTime: CMTime, max maxTime: CMTime) -> CMTime {
        if CMTimeCompare(time, minTime) < 0 { return minTime }
        if CMTimeCompare(time, maxTime) > 0 { return maxTime }
        return time
    }
}

private extension CSCameraCapabilities {
    static let empty = CSCameraCapabilities(
        resolutionOptions: [],
        fpsOptions: [],
        shutterOptions: [],
        isoOptions: [],
        supportsLowLightBoost: false
    )
}

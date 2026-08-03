//
//  NDExposurePlannerTests.swift
//  CineSetTests
//
//  Created by edgar kosyan on 15/07/2026.
//

import AVFoundation
import Foundation
import Testing
@testable import CineSet

struct NDExposurePlannerTests {
    @Test func requiredNDForSlowerTargetShutter() {
        let required = NDExposurePlanner.requiredNDStops(
            meteredShutter: 3200,
            meteredISO: 50,
            targetShutter: 50,
            targetISO: 50
        )

        #expect(abs(required - 6) < 0.0001)
    }

    @Test func requiredZeroSelectedZeroIsNotRequired() {
        let plan = NDExposurePlanner.plan(
            meteredShutter: 50,
            meteredISO: 100,
            targetShutter: 50,
            targetISO: 100,
            selectedNDStops: 0
        )

        #expect(plan.requiredNDStops == 0)
        #expect(plan.matchState == .notRequired)
        #expect(plan.differenceStops == 0)
    }

    @Test func requiredThreeSelectedZeroIsInsufficient() {
        let plan = NDExposurePlanner.plan(
            meteredShutter: 800,
            meteredISO: 100,
            targetShutter: 100,
            targetISO: 100,
            selectedNDStops: 0
        )

        #expect(abs(plan.requiredNDStops - 3) < 0.0001)
        if case .insufficient(let missing) = plan.matchState {
            #expect(abs(missing - 3) < 0.0001)
        } else {
            Issue.record("Expected insufficient match state")
        }
    }

    @Test func requiredThreeSelectedThreeIsMatched() {
        let plan = NDExposurePlanner.plan(
            meteredShutter: 800,
            meteredISO: 100,
            targetShutter: 100,
            targetISO: 100,
            selectedNDStops: 3.0
        )

        #expect(plan.matchState == NDMatchState.matched)
        #expect(abs(plan.differenceStops) <= NDExposurePlanner.stopTolerance)
    }

    @Test func requiredThreeSelectedFourIsStronger() {
        let plan = NDExposurePlanner.plan(
            meteredShutter: 800,
            meteredISO: 100,
            targetShutter: 100,
            targetISO: 100,
            selectedNDStops: 4
        )

        if case .stronger(let extra) = plan.matchState {
            #expect(abs(extra - 1) < 0.0001)
        } else {
            Issue.record("Expected stronger match state")
        }
        #expect(abs(plan.differenceStops - 1) < 0.0001)
    }

    @Test func matchToleranceTreatsNearMatchAsMatched() {
        let state = NDExposurePlanner.matchState(requiredNDStops: 3.0, selectedNDStops: 3.4)
        #expect(state == NDMatchState.matched)
    }

    @Test func matchToleranceTreatsNearMissAsInsufficient() {
        let state = NDExposurePlanner.matchState(requiredNDStops: 3.0, selectedNDStops: 2.4)
        if case .insufficient(let missing) = state {
            #expect(abs(missing - 0.6) < 0.0001)
        } else {
            Issue.record("Expected insufficient match state")
        }
    }

    @Test func nd32Nd64Nd128ProduceDifferentMatchStatesWhenRequiredIsFive() {
        let requiredContext = (
            meteredShutter: 3200,
            meteredISO: Float(50),
            targetShutter: 100,
            targetISO: Float(50)
        )

        let nd32 = NDExposurePlanner.plan(
            meteredShutter: requiredContext.meteredShutter,
            meteredISO: requiredContext.meteredISO,
            targetShutter: requiredContext.targetShutter,
            targetISO: requiredContext.targetISO,
            selectedNDStops: 5.0
        )
        let nd64 = NDExposurePlanner.plan(
            meteredShutter: requiredContext.meteredShutter,
            meteredISO: requiredContext.meteredISO,
            targetShutter: requiredContext.targetShutter,
            targetISO: requiredContext.targetISO,
            selectedNDStops: 6.0
        )
        let nd128 = NDExposurePlanner.plan(
            meteredShutter: requiredContext.meteredShutter,
            meteredISO: requiredContext.meteredISO,
            targetShutter: requiredContext.targetShutter,
            targetISO: requiredContext.targetISO,
            selectedNDStops: 7.0
        )

        #expect(abs(nd32.requiredNDStops - 5) < 0.1)
        #expect(nd32.matchState == NDMatchState.matched)
        if case .stronger(let extra64) = nd64.matchState {
            #expect(abs(extra64 - 1) < 0.0001)
        } else {
            Issue.record("Expected ND64 to be stronger")
        }
        if case .stronger(let extra128) = nd128.matchState {
            #expect(abs(extra128 - 2) < 0.0001)
        } else {
            Issue.record("Expected ND128 to be stronger")
        }
        #expect(nd32.matchState != nd64.matchState)
        #expect(nd64.matchState != nd128.matchState)
    }

    @Test func invalidInputsReturnZeroRequiredND() {
        let required = NDExposurePlanner.requiredNDStops(
            meteredShutter: 0,
            meteredISO: .nan,
            targetShutter: 50,
            targetISO: 100
        )

        #expect(required == 0)
    }

    @Test func previewBrightnessIsNeutralWhenNDMatchesRequired() {
        let brightness = NDExposurePlanner.previewBrightnessAdjustment(
            requiredNDStops: 6,
            selectedNDStops: 6
        )

        #expect(brightness == 0)
    }

    @Test func previewBrightnessBrightensWhenNDIsInsufficient() {
        let brightness = NDExposurePlanner.previewBrightnessAdjustment(
            requiredNDStops: 6,
            selectedNDStops: 3
        )

        #expect(abs(brightness - 0.21) < 0.0001)
    }

    @Test func previewBrightnessDarkensWhenNDIsStronger() {
        let brightness = NDExposurePlanner.previewBrightnessAdjustment(
            requiredNDStops: 6,
            selectedNDStops: 8
        )

        #expect(abs(brightness - (-0.14)) < 0.0001)
    }

    @Test func previewBrightnessIsCapped() {
        let brightness = NDExposurePlanner.previewBrightnessAdjustment(
            requiredNDStops: 10,
            selectedNDStops: 0
        )

        #expect(brightness == 0.35)
    }

    @Test func shutterDenominatorConversion() {
        let duration = CMTime(value: 1, timescale: 3200)
        #expect(CSCameraVideoSessionService.shutterDenominator(from: duration) == 3200)
    }
}

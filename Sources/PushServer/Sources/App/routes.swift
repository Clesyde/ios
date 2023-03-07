import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.redirect(to: "https://mobile.clesyde.lu")
    }

    app.group("push") { push in
        let pushTopic = Environment.get("APNS_TOPIC") ?? "io.robbie.HomeAssistant"
        let pushController = PushController(appIdPrefix: pushTopic)

        push.post("send") { req in
            try await pushController.send(req: req)
        }
    }

    app.group("rate_limits") { rateLimits in
        let rateLimitsController = RateLimitsController()

        rateLimits.post("check") { req in
            try await rateLimitsController.check(req: req)
        }
    }
}

import { application } from "controllers/application"

// Explicitly register controllers so they load synchronously (no silent dynamic import failures)
import RevealController from "controllers/reveal_controller"
application.register("reveal", RevealController)

import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)

import SubmitOnKeyupController from "controllers/submit_on_keyup_controller"
application.register("submit-on-keyup", SubmitOnKeyupController)

import HostnameController from "controllers/hostname_controller"
application.register("hostname", HostnameController)

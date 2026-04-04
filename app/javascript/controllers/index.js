import { application } from "controllers/application"

// Explicitly register controllers so they load synchronously (no silent dynamic import failures)
import RevealController from "controllers/reveal_controller"
application.register("reveal", RevealController)

import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)

import { application } from "controllers/application"
import ThemeController from "controllers/theme_controller"

application.register("theme", ThemeController)

export { application }

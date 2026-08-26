import { application } from "controllers/application"
import ThemeController from "controllers/theme_controller"
import DropdownController from "controllers/dropdown_controller"

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)

export { application }

import { application } from "./application"

import SubsectionSelectController from "./subsection_select_controller"
application.register("subsection-select", SubsectionSelectController)

import EmbedPreviewController from "./embed_preview_controller"
application.register("embed-preview", EmbedPreviewController)

import SidebarToggleController from "./sidebar_toggle_controller"
application.register("sidebar-toggle", SidebarToggleController)
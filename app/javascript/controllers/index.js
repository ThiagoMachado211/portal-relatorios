import { application } from "./application"

import SubsectionSelectController from "./subsection_select_controller"
application.register("subsection-select", SubsectionSelectController)

import EmbedPreviewController from "./embed_preview_controller"
application.register("embed-preview", EmbedPreviewController)
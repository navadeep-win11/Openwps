# Presentation Engine Selection and Compatibility

## Engine Research
I investigated potential approaches for building the Presentation editor.
A mature, customizable 16:9 canvas editor specifically tailored for presentations does not exist out-of-the-box in the Flutter package ecosystem in a way that allows deep programmatic serialization compatible with local-first file persistence.
I decided to build a **Custom Flutter Canvas** using an absolute positioning coordinate system representing a 1920x1080 logical resolution. This gives us full control to implement drag-and-drop, resize, z-order, and text editing exactly as required.

For PPTX Export/Import: The Dart ecosystem currently lacks a maintained, robust package for reading/writing full OpenXML Presentation files (`.pptx`). There are viewing packages and some niche structural generators, but they either lack feature parity with our custom elements or suffer from version conflicts with `archive` and `xml`.
Therefore, **PPTX generation and parsing is explicitly deferred** for this milestone. I am documenting this limitation per the instructions.

## Remaining Architecture Steps
I will structure the implementation into `lib/features/presentation/` containing the document model, the 16:9 interactive canvas, gesture handlers, and the toolbars.

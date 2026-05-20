// Minimal typings for `gifsicle-wasm-browser` — the package ships no types.
// Runs the gifsicle GIF optimiser (compiled to WebAssembly) in the browser.
declare module "gifsicle-wasm-browser" {
  interface GifsicleInput {
    /** Source GIF — a File/Blob, or a URL string. */
    file: File | Blob | string;
    /** Virtual filename the command lines reference. */
    name: string;
  }

  interface GifsicleRunOptions {
    input: GifsicleInput[];
    /** One or more gifsicle command lines (output to /out/...). */
    command: string[];
  }

  const gifsicle: {
    run(options: GifsicleRunOptions): Promise<File[]>;
  };

  export default gifsicle;
}

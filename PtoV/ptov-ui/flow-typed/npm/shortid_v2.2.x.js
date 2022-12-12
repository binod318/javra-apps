// flow-typed signature: 8a5a8546c057b7d76b5e18fd32e964d3
// flow-typed version: 587cb4dca6/shortid_v2.2.x/flow_>=v0.25.x

declare module 'shortid' {
  declare type ShortIdModule = {|
    (): string,
    generate(): string,
    seed(seed: number): ShortIdModule,
    worker(workerId: number): ShortIdModule,
    characters(characters: string): string,
    decode(id: string): { version: number, worker: number },
    isValid(id: mixed): boolean,
  |};
  declare module.exports: ShortIdModule;
};

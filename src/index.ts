import ReactNativeHashcashModule from './ReactNativeHashcashModule';

export async function calculateHashcash(k: number, value: string) {
  return await ReactNativeHashcashModule.calculateHashcash(k, value);
}

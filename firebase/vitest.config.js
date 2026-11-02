import { defineConfig } from 'vitest/config';

// Test files share one emulator and each clears it, so run them one at a time.
export default defineConfig({
  test: {
    fileParallelism: false,
  },
});

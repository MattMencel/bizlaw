import { test, expect } from '@playwright/test';

test('homepage has title and sign in link', async ({ page }) => {
  await page.goto('/');

  // Expect the page title to contain a welcome message
  await expect(page).toHaveTitle(/Business Law Platform/);

  // Expect the page to have a "Sign In" link when not logged in
  const signInLink = page.getByText('Sign In');
  await expect(signInLink).toBeVisible();
});

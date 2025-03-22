export function toNumericId(id: string | undefined): number {
  if (!id) return 0;
  const parsed = parseInt(id, 10);
  return isNaN(parsed) ? 0 : parsed;
}

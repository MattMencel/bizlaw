/**
 * Type guard to check if a string value is a valid enum value.
 *
 * @param enumObject The enum object to check against
 * @param value The string value to validate
 * @returns Boolean indicating if the value exists in the enum
 */
export function isValidEnumValue<T>(
  enumObject: { [k: string]: T },
  value: string | null | undefined,
): value is string & T {
  if (!value) return false;
  return Object.values(enumObject).includes(value as any);
}

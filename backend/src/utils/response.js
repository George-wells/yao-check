/**
 * Standard API response helpers
 */

class ApiResponse {
  /**
   * Success response
   */
  static success(res, data = null, message = 'Success', statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Created response
   */
  static created(res, data = null, message = 'Created successfully') {
    return ApiResponse.success(res, data, message, 201);
  }

  /**
   * Paginated response
   */
  static paginated(res, data, total, page, pageSize, message = 'Success') {
    return res.status(200).json({
      success: true,
      message,
      data,
      pagination: {
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
        hasMore: page * pageSize < total,
      },
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Error response
   */
  static error(res, message = 'Internal Server Error', statusCode = 500, errors = null) {
    const response = {
      success: false,
      message,
      timestamp: new Date().toISOString(),
    };
    if (errors) {
      response.errors = errors;
    }
    return res.status(statusCode).json(response);
  }

  /**
   * Bad request
   */
  static badRequest(res, message = 'Bad Request', errors = null) {
    return ApiResponse.error(res, message, 400, errors);
  }

  /**
   * Unauthorized
   */
  static unauthorized(res, message = 'Unauthorized') {
    return ApiResponse.error(res, message, 401);
  }

  /**
   * Forbidden
   */
  static forbidden(res, message = 'Forbidden') {
    return ApiResponse.error(res, message, 403);
  }

  /**
   * Not found
   */
  static notFound(res, message = 'Resource not found') {
    return ApiResponse.error(res, message, 404);
  }

  /**
   * Conflict
   */
  static conflict(res, message = 'Resource already exists') {
    return ApiResponse.error(res, message, 409);
  }

  /**
   * Too many requests
   */
  static tooManyRequests(res, message = 'Too many requests, please try again later') {
    return ApiResponse.error(res, message, 429);
  }
}

module.exports = ApiResponse;

from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):

    response = exception_handler(exc, context)

    if response is not None:

        # Validation errors
        if response.status_code == 400:
            return Response(
                {
                    "success": False,
                    "message": "Invalid request data.",
                    "errors": response.data
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Authentication
        if response.status_code == 401:
            return Response(
                {
                    "success": False,
                    "message": "Authentication required."
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Permission
        if response.status_code == 403:
            return Response(
                {
                    "success": False,
                    "message": "You do not have permission to perform this action."
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # Not found
        if response.status_code == 404:
            return Response(
                {
                    "success": False,
                    "message": "The requested resource was not found."
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Other DRF errors
        return Response(
            {
                "success": False,
                "message": "Unable to process the request."
            },
            status=response.status_code
        )

    # Unexpected server error
    return Response(
        {
            "success": False,
            "message": "An unexpected server error occurred."
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )
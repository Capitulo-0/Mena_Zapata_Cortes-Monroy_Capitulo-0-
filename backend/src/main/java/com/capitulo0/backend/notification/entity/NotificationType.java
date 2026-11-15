package com.capitulo0.backend.notification.entity;

/**
 * Tipos persistidos en user_notifications.type (migración V9).
 * Los textos de la interfaz se definen por separado en Flutter.
 */
public enum NotificationType {
    /** Solicitud de seguimiento de una cuenta privada aún sin resolver. */
    FOLLOW_REQUEST,

    /** Alguien comenzó a seguir al destinatario. */
    NEW_FOLLOWER,

    /** La solicitud enviada por el destinatario fue autorizada. */
    FOLLOW_ACCEPTED
}
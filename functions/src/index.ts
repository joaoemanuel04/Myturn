import {onValueDeleted} from "firebase-functions/v2/database";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.database();

const region = "us-central1";

export const onClientRemoved = onValueDeleted(
  {
    ref: "/filas/{establishmentId}/clientes/{clientId}",
    region: region,
  },
  async (event) => {
    const {establishmentId, clientId} = event.params;
    console.log(`Cliente ${clientId} removido da fila do ${establishmentId}`);

    const queueRef = event.data.ref.parent;
    if (!queueRef) {
      console.log("Referência para a fila não encontrada.");
      return;
    }

    const remainingClientsSnapshot =
      await queueRef.orderByChild("horaEntrada").get();

    if (!remainingClientsSnapshot.exists()) {
      console.log("A fila está vazia. Nenhuma notificação para enviar.");
      return;
    }

    const remainingClients: {uid: string; [key: string]: unknown}[] = [];
    remainingClientsSnapshot.forEach((child) => {
      remainingClients.push({uid: child.key ?? "", ...child.val()});
    });

    const nextClient = remainingClients[0];
    if (!nextClient?.uid) {
      console.log("Não foi possível determinar o próximo cliente.");
      return;
    }

    console.log(`Próximo cliente na fila: ${nextClient.uid}`);

    const userTokenSnapshot =
      await db.ref(`/users/${nextClient.uid}/fcmToken`).get();
    if (!userTokenSnapshot.exists()) {
      console.log(`Token FCM não encontrado para o usuário ${nextClient.uid}`);
      return;
    }
    const fcmToken = userTokenSnapshot.val();

    const establishmentSnapshot =
      await db.ref(`/estabelecimentos/${establishmentId}/name`).get();
    const establishmentName = establishmentSnapshot.val() || "o estabelecimento";

    try {
      // ✅ AJUSTE FINAL NA ESTRUTURA DA MENSAGEM
      const message = {
        notification: {
          title: "Sua vez está chegando! 🎉",
          body: `Você é o próximo na fila do ${establishmentName}. Prepare-se!`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          screen: "fila_ativa",
          establishmentId: establishmentId,
        },
        token: fcmToken,
        android: {
          notification: {
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      await admin.messaging().send(message);
      console.log("Notificação enviada com sucesso!");

    } catch (error) {
      console.error("Erro ao enviar notificação:", error);
    }
  }
);